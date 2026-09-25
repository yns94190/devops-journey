# Semaine 09 — Kubernetes (k3s)

## 1. Objectifs
- Installer k3s (Kubernetes léger) sur le VPS `devops-server` (semaine-05)
- Déployer l'app de semaine-02 (Nginx → App Python → PostgreSQL) sur le cluster

Ce fichier couvre l'étape 1 (installation). Le déploiement de l'app suit dans une étape séparée.

## 2. Pourquoi k3s plutôt que kubeadm/K8s complet
- Un seul nœud, ressources limitées (Free Tier ARM, 1 OCPU / 6 Go RAM) : k3s (Rancher) est conçu pour ces contraintes (binaire unique, etcd remplacé par SQLite en mono-nœud, empreinte mémoire réduite)
- Objectif pédagogique : comprendre Kubernetes sans la complexité opérationnelle d'un control plane multi-composants à gérer à la main

## 3. Conflit de port anticipé avec la stack Docker Compose existante
La stack de semaine-02 tourne toujours sur `devops-server` (`docker compose up -d`, nginx sur `:80`, app sur `:8080`). k3s installe par défaut Traefik (ingress) + ServiceLB, qui réservent les ports `80`/`443` de l'hôte → conflit direct avec `docker-proxy` déjà lié sur `:80`.

**Choix :** installation avec `--disable traefik --disable servicelb`, pour garder un cluster propre sans pods en crash loop. L'exposition de l'app sur k3s sera décidée explicitlement à l'étape de déploiement (Ingress/NodePort, probablement après avoir arrêté la stack Docker Compose pour libérer le port 80).

```bash
curl -sfL https://get.k3s.io | sudo sh -s - --disable traefik --disable servicelb
```

Résultat : k3s v1.36.4+k3s1 installé, service systemd `k3s` activé et démarré, nœud `devops-server` `Ready` (rôle `control-plane`).

## 4. Mise en réseau : firewalld vs k3s

### Symptôme initial
Après activation du masquerade firewalld (nécessaire pour le NAT des pods), deux problèmes :
- `metrics-server` restait `0/1` : `Failed to scrape node ... dial tcp 10.0.0.157:10250: connect: no route to host` → firewalld bloquait le port kubelet (`10250/tcp`) même en local
- Un test `nslookup kubernetes.default` depuis un pod BusyBox retournait `NXDOMAIN`

### ⚠️ Erreur de diagnostic (leçon)
Le premier symptôme (port 10250) était réel et corrigé en l'ouvrant dans la zone `public`, et en ajoutant les CIDR pods (`10.42.0.0/16`) et services (`10.43.0.0/16`) à la zone `trusted` de firewalld (recommandation connue pour k3s + firewalld/nftables sur RHEL9). `metrics-server` est repassé `1/1 Running`.

Le second symptôme (`NXDOMAIN`) a persisté après ce correctif, ce qui a conduit à une conclusion **erronée** : un conflit nftables/kube-proxy nécessitant de désactiver firewalld entièrement. Après désactivation complète (`systemctl disable --now firewalld`), le même test `nslookup kubernetes.default` échouait **toujours** — preuve que firewalld n'était pas en cause.

**Cause réelle :** `kubernetes.default` est un nom court, pas un FQDN. Le `nslookup` de BusyBox ne rejoue pas correctement la liste `search` de `/etc/resolv.conf` (`default.svc.cluster.local svc.cluster.local cluster.local ...`, `ndots:5`) comme le ferait un résolveur glibc — il n'affiche que l'échec sur le nom brut. Un test avec le nom complet a immédiatement fonctionné :
```
nslookup kubernetes.default.svc.cluster.local
→ Address: 10.43.0.1   ✅
wget https://1.1.1.1 → INTERNET_OK   ✅
```

**Conséquence :** firewalld a été désactivé puis **réactivé** avec la configuration qui fonctionnait déjà (masquerade + CIDR trusted + port 10250) — aucune dégradation de sécurité conservée. Le cluster reste pleinement fonctionnel avec firewalld actif.

**Leçon pour la suite :** toujours valider avec un test irréprochable (nom pleinement qualifié, outils fiables) avant de conclure à une panne infra et modifier des règles de sécurité — un outil de test limité (ici BusyBox `nslookup`) peut produire un faux négatif.

### Configuration firewalld finale
```
zone trusted : sources 10.42.0.0/16 (pods), 10.43.0.0/16 (services), target ACCEPT
zone public  : services dhcpv6-client, http, ssh + port 10250/tcp (kubelet), masquerade: yes
```
Port `6443/tcp` (API Kubernetes) volontairement **non ouvert** à l'extérieur — `kubectl` reste utilisable uniquement via SSH sur le VPS pour l'instant.

## 5. Accès kubectl sans sudo
Le binaire `k3s` fait office de `kubectl` (symlink), mais son mode de résolution du kubeconfig par défaut pointe sur `/etc/rancher/k3s/k3s.yaml` (root:root, `0600`) même quand `~/.kube/config` existe. Copié pour l'utilisateur `opc` :
```bash
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown opc:opc ~/.kube/config && chmod 600 ~/.kube/config
echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
```

## 6. Validation finale
```
kubectl get nodes
NAME            STATUS   ROLES           VERSION
devops-server   Ready    control-plane   v1.36.4+k3s1

kubectl get pods -A
kube-system   coredns-...                  1/1   Running
kube-system   local-path-provisioner-...   1/1   Running
kube-system   metrics-server-...           1/1   Running
```
Pas de pods Traefik/ServiceLB (désactivés à l'installation, comme prévu).

## Points clés
- k3s adapté aux contraintes Free Tier (1 OCPU / 6 Go) — empreinte bien plus légère qu'un K8s complet
- `--disable traefik --disable servicelb` à l'installation pour éviter un conflit de port avec la stack Docker Compose existante, le temps de décider l'exposition de l'app volontairement
- k3s + firewalld (RHEL9/nftables) nécessite des règles explicites (CIDR pods/services en zone `trusted`, port kubelet `10250`) — pas besoin de désactiver firewalld si ces règles sont posées correctement
- Toujours tester avec un FQDN et des outils fiables avant de diagnostiquer une panne réseau côté cluster
- `k3s kubectl` (symlink) ignore `~/.kube/config` par défaut sans `KUBECONFIG` explicite, contrairement à un `kubectl` standard

## Reste à faire
- Décider du mode d'exposition de l'app de semaine-02 sur k3s (Ingress + réactivation de Traefik, ou NodePort) et arrêter la stack Docker Compose correspondante pour libérer le port 80
- Écrire les manifests (`semaine-09/manifests/`) : Deployment app, Service, ConfigMap/Secret pour la config PostgreSQL, StatefulSet ou Deployment + PVC pour PostgreSQL
- Déployer et valider l'accès externe à l'app via le cluster
