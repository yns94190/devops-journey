# Semaine 05 — VPS

## Environnement
- Provider : Oracle Cloud (Free Tier), instance ARM (aarch64)
- OS : Oracle Linux 9
- User : `opc` (utilisateur par défaut Oracle Linux, sudoer)
- Accès : SSH par clé publique (pas de mot de passe)
- IP publique réelle : volontairement absente de ce repo (public) — voir `.vps-local.md` (gitignored) en local

## 1. Installation Docker (Oracle Linux 9 / dnf)
Oracle Linux utilise `dnf`, pas `apt` — le dépôt officiel Docker existe en version RHEL.

```bash
sudo dnf -y install dnf-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # se reconnecter pour que ça prenne effet
docker run --rm hello-world     # vérification
```

## 2. Firewall local (firewalld)
Oracle Linux utilise `firewalld` (contrairement à Ubuntu/`ufw`).

```bash
sudo firewall-cmd --list-all                    # état actuel
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
sudo firewall-cmd --list-all                    # vérification
```
- `ssh` et `dhcpv6-client` étaient déjà autorisés par défaut
- `http` (port 80) ajouté pour exposer l'app

## 3. Déploiement de l'app (semaine-02)
Le repo étant public, on le clone directement sur le VPS :

```bash
git clone https://github.com/yns94190/devops-journey.git
cd devops-journey/semaine-02/compose

# .env généré directement sur la machine cible (jamais transporté en clair)
DBPASS=$(openssl rand -hex 16)
cat > .env << EOF
DB_HOST=db
DB_NAME=devops
DB_USER=yanis
DB_PASSWORD=${DBPASS}
POSTGRES_DB=devops
POSTGRES_USER=yanis
POSTGRES_PASSWORD=${DBPASS}
EOF

sudo docker compose up -d --build
sudo docker compose ps
curl http://localhost
```

Résultat : 3 containers (`app`, `db`, `nginx`) démarrés, `db` healthy, réponse `Hello from Docker! DB: PostgreSQL 16.15...` en local sur le VPS.

## 4. Debug réseau OCI — accès externe en timeout

Après le déploiement, `curl http://<ip-vps>` **depuis l'extérieur** timeout alors que ça fonctionnait en local sur le VPS. Sur Oracle Cloud, une requête entrante traverse plusieurs couches de filtrage indépendantes, **toutes doivent laisser passer le trafic** :

```
Internet
  │
  ▼
Internet Gateway (IGW)         — passerelle du VCN vers Internet
  │
  ▼
Route Table                    — route le trafic 0.0.0.0/0 vers l'IGW
  │
  ▼
Security List (niveau subnet)  — règles ingress/egress du VCN
  │
  ▼
Network Security Group (NSG)   — règles ingress/egress attachées à la VNIC
  │
  ▼
firewalld (niveau OS)          — pare-feu de l'instance
  │
  ▼
Application (nginx:80)
```

### Diagnostic
1. **Vérif Route Table / Internet Gateway** : déjà correctement configurés dès le départ — le SSH (port 22) fonctionnait déjà depuis l'extérieur, ce qui prouve que la route par défaut vers l'Internet Gateway était bonne. Cette couche n'a donc pas eu besoin d'être touchée.
2. **Vérif `firewalld`** : `sudo firewall-cmd --list-all` montrait bien `http` dans les services autorisés → pas le problème.
3. **Vérif ports en écoute** (`ss -tlnp`) : `nginx` (via `docker-proxy`) bien en écoute sur `0.0.0.0:80` et `[::]:80` → pas le problème.
4. **Capture réseau (`tcpdump`)** sur le VPS pendant une requête externe :
   ```bash
   sudo tcpdump -i any -n "tcp port 80"
   ```
   → **aucun paquet SYN externe n'atteignait la carte réseau de la machine**. Ça a permis d'exclure définitivement l'OS (firewalld, Docker) et de confirmer que le blocage se faisait en amont, au niveau réseau cloud OCI.
5. **Security List du subnet** : ne contenait au départ qu'une règle ingress pour SSH (port 22) — ajout d'une règle ingress TCP/80, source `0.0.0.0/0`.
6. **Network Security Group (NSG)** attachée à la VNIC de l'instance : règle ingress TCP/80 absente également — ajoutée en plus de la Security List.

### Point clé : Security List et NSG sont cumulatives
Sur OCI, si une VNIC est à la fois soumise à une Security List (niveau subnet) et à une ou plusieurs NSG (niveau VNIC), **les deux doivent autoriser le trafic** — l'une ne remplace pas l'autre. Ouvrir le port uniquement dans la NSG (ou uniquement dans la Security List) ne suffit pas si l'autre couche est encore restrictive.

### Résultat final
Après ajout de la règle dans **les deux** (Security List + NSG) :
```bash
curl http://<ip-vps>
# → HTTP/1.1 200, "Hello from Docker! DB: PostgreSQL 16.15..."
```
Vérifié aussi bien depuis un poste externe (WSL) que depuis le VPS lui-même (`localhost` et IP publique en hairpin NAT).

## Bonnes pratiques retenues
- Sur un cloud provider, toujours distinguer le firewall **OS** (`firewalld`, `ufw`, iptables...) du firewall **réseau** (Security Groups, Security Lists, NSG) — un `curl` qui marche en local sur la machine mais pas depuis l'extérieur pointe presque toujours vers la couche réseau cloud, pas l'OS
- Sur OCI spécifiquement : vérifier Security List **et** NSG si les deux sont utilisées, elles sont additives, pas alternatives
- `tcpdump` côté serveur pendant un test externe est le moyen le plus rapide de savoir si le trafic arrive seulement jusqu'à la machine ou pas du tout
- Ne jamais désactiver `firewalld` par facilité — n'ouvrir que les ports nécessaires
- Générer les secrets (`.env`) directement sur la machine cible plutôt que de les transporter en clair
