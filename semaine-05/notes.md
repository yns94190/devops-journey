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

## ⚠️ Spécificité Oracle Cloud : double firewall
Sur Oracle Cloud, le trafic passe par **deux couches** de firewall :
1. **`firewalld`** sur l'instance (OS) — configuré ci-dessus
2. **Security List / Network Security Group** du VCN (niveau réseau cloud, dans la console OCI)

Une route bloquée par la Security List ne sera jamais visible dans `firewalld` : `curl` en local sur le VPS peut réussir alors que l'accès externe timeout. Il faut ajouter une règle d'ingress (ex: TCP/80, source `0.0.0.0/0`) dans **Networking → Virtual Cloud Networks → Security Lists** de la console OCI en plus de la config `firewalld`.

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
