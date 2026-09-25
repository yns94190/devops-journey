# Semaine 10 — Monitoring & Observabilité (Prometheus + Grafana)

## 1. Objectif
Installer une stack de monitoring sur le cluster k3s de semaine-09 (`devops-server`) : métriques du nœud, du cluster, et des workloads (`app`/`postgres` de semaine-02), visualisables dans Grafana.

## 2. Choix : kube-prometheus-stack (Helm)
Chart `prometheus-community/kube-prometheus-stack` : bundle Prometheus Operator + Prometheus + Grafana + kube-state-metrics + node-exporter + dashboards par défaut. Standard de facto en entreprise — plus formateur qu'un montage manuel de chaque composant.

Helm installé sans sudo dans `~/.local/bin` (même approche que Terraform en semaine-07) :
```bash
HELM_INSTALL_DIR=/home/opc/.local/bin USE_SUDO=false bash get_helm.sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

## 3. Dimensionnement pour le nœud contraint (1 OCPU / 6 Go ARM, Free Tier)
Valeurs personnalisées dans `semaine-10/helm/values.yaml` :
- **Alertmanager désactivé** — pas de destinataire de notifications dans un lab solo
- **kube-controller-manager / kube-scheduler / kube-proxy / etcd monitors désactivés** — k3s ne les expose pas comme un cluster kubeadm classique ; les laisser activés ne produit que des cibles Prometheus "down" en permanence
- **Rétention Prometheus réduite à 2 jours**, PVC 2Gi (`local-path`)
- Ressources (`requests`/`limits`) réduites sur tous les composants (`kube-state-metrics`, `node-exporter`, `prometheus`)

## 4. Grafana : trois problèmes de démarrage rencontrés et résolus

### a) Plugins par défaut trop lents à télécharger
Le chart Grafana installe par défaut des "Explore Apps" (traces, logs...) inutiles ici (pas de Loki/Tempo) — leur téléchargement dépassait le délai de la sonde liveness sur ce nœud ARM, provoquant un redémarrage en boucle dès le premier déploiement. **Fix :** `grafana.plugins: []`.

### b) Sous-chemin `/grafana` mal géré (`serve_from_sub_path`)
Premier essai avec `serve_from_sub_path: true` : la sonde de santé (`/api/health`, tapée directement sur le port du conteneur, donc *sans* le préfixe `/grafana`) entrait en conflit avec la logique de sous-chemin de Grafana → `503`/timeouts. **Fix retenu :** laisser Grafana ignorer le sous-chemin (`serve_from_sub_path: false`, `root_url` gardé pour la génération de liens) et faire retirer le préfixe `/grafana` **par Traefik**, via un `Middleware` CRD (`semaine-10/helm/grafana-middleware.yaml`, `stripPrefix`) référencé en annotation sur l'Ingress du chart. Grafana reçoit alors les requêtes comme s'il était servi à la racine — plus simple et plus robuste que d'adapter les sondes au sous-chemin.

### c) `OOMKilled` à 256Mi
Après les deux fixes précédents, le pod redémarrait encore — cette fois `Reason: OOMKilled`, `Exit Code: 137`. Grafana 13.2.2 (apiserver interne, stockage "unifié", plusieurs sous-applications embarquées) consomme nettement plus que les anciennes versions au démarrage. **Fix :** limite mémoire remontée de `256Mi` à `768Mi`. Stable depuis (aucun redémarrage, ~400 Mi observés en usage réel).

**Leçon (cf. [[feedback-diagnostic-verification]]) :** trois symptômes différents (503, timeout, OOMKilled) pour ce qui ressemblait au même problème de démarrage — chacun avait sa propre cause distincte. Ne pas s'arrêter au premier fix qui semble plausible ; revérifier après chaque changement (`kubectl describe pod` → `Last State`/`Reason` donne la vraie cause, pas de supposition).

## 5. Secrets
Comme pour `postgres-credentials` (semaine-09), le Secret `grafana-admin-credentials` est créé directement sur le cluster (mot de passe généré avec `openssl rand -base64 18`), jamais commité :
```bash
kubectl create secret generic grafana-admin-credentials -n monitoring \
  --from-literal=admin-user=admin --from-literal=admin-password=<généré>
```
Référencé dans `values.yaml` via `grafana.admin.existingSecret`.

## 6. Exposition
Ingress Traefik sur le chemin `/grafana` (coexiste avec l'Ingress `/` de l'app de semaine-09 sur le même contrôleur — Traefik route par préfixe le plus spécifique). Pas de nouveau port ouvert côté OCI/firewalld : tout transite par le port 80 déjà autorisé.

## 7. Validation
```bash
kubectl get pods -n monitoring
# grafana, kube-state-metrics, operator, node-exporter, prometheus : tous Running, 0 restart (stable)

curl -I http://141.253.108.240/grafana/login
# HTTP/1.1 200 OK

curl http://141.253.108.240/                 # app semaine-09 : pas de régression
# Hello from Docker! DB: PostgreSQL 16.15...
```

## Points clés
- `kube-prometheus-stack` est un bon choix pédagogique (standard de l'industrie) mais lourd par défaut pour un nœud Free Tier — désactiver les composants non pertinents pour k3s (etcd/scheduler/controller-manager/kube-proxy monitors, Alertmanager) et sur-dimensionner prudemment plutôt que de couper les ressources au plus juste
- Un Middleware Traefik (`stripPrefix`) est une solution plus robuste que `serve_from_sub_path` pour exposer une appli sous un chemin `/xxx` via Ingress — évite les pièges de configuration des sondes
- Toujours vérifier `Last State`/`Reason` (`OOMKilled` vs `Error`/signal) avant de re-diagnostiquer — deux symptômes identiques en apparence (redémarrage en boucle) peuvent avoir des causes totalement différentes

## Reste à faire
- Explorer les dashboards par défaut fournis par le chart (Kubernetes / Nodes / Pods) et éventuellement en importer un dédié à l'app (latence HTTP, erreurs)
- `ServiceMonitor` custom pour scraper les métriques applicatives si l'app en exposait un jour (`/metrics`)
- Alertmanager + règles d'alerte si le lab évolue vers un usage moins ponctuel
