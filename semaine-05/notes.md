# Semaine 05 — VPS

## Environnement
- Provider : Oracle Cloud (Free Tier), instance ARM (aarch64)
- OS : Oracle Linux 9
- User : `opc` (utilisateur par défaut Oracle Linux, sudoer)
- Accès : SSH par clé publique (pas de mot de passe)

## Installation Docker (Oracle Linux 9 / dnf)
```bash
sudo dnf -y install dnf-utils
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker $USER   # se reconnecter pour que ça prenne effet
```

## Firewall (firewalld)
Oracle Linux utilise `firewalld` (contrairement à Ubuntu/`ufw`).
```bash
sudo firewall-cmd --list-all                    # état actuel
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload
```
- `ssh` et `dhcpv6-client` étaient déjà autorisés par défaut
- `http` (port 80) ajouté pour exposer l'app

## ⚠️ Spécificité Oracle Cloud : triple firewall
Sur Oracle Cloud, le trafic passe par **trois couches** de filtrage, qui doivent TOUTES autoriser le port :
1. **`firewalld`** sur l'instance (OS)
2. **Security List** du subnet (VCN, niveau réseau cloud)
3. **Network Security Group (NSG)** attachée à la VNIC de l'instance (si utilisée)

Security List et NSG sont **cumulatives** (une seule des deux ne suffit pas si les deux sont en place) : il faut une règle d'ingress TCP/80 (source `0.0.0.0/0`) dans **les deux**. Diagnostic confirmé par `tcpdump` côté VPS : tant que ce n'était pas fait sur les deux couches, aucun paquet SYN externe n'atteignait même la carte réseau de la machine — `firewalld` n'avait rien à voir là-dedans.

**Résultat final :** `curl http://<ip-vps>` → `200 OK` avec la réponse de l'app.

## Déploiement de l'app (semaine-02)
```bash
git clone https://github.com/yns94190/devops-journey.git
cd devops-journey/semaine-02/compose
# créer .env (voir README racine pour les clés attendues)
sudo docker compose up -d --build
sudo docker compose ps
curl http://localhost
```

## Bonnes pratiques
- Toujours vérifier les deux couches de firewall sur un cloud provider (OS + réseau cloud)
- Ne jamais désactiver `firewalld` par facilité — n'ouvrir que les ports nécessaires
- Générer les secrets (`.env`) sur la machine cible plutôt que de les transporter en clair
