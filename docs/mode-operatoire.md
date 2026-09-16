# Mode Opératoire — Parcours DevOps 12 Semaines

## Environnement de travail
- OS : Windows + WSL2 Ubuntu
- Éditeur : VS Code connecté à WSL
- Shell : Bash

## Outils installés
- Git
- Docker
- Trivy
- Semgrep (via GitHub Actions)
- pytest

---

## SEMAINE 01 — Linux & Git

### Environnement
- WSL2 + Ubuntu installé via `wsl --install -d Ubuntu`
- VS Code connecté à WSL via extension "WSL"
- Packages installés : `git curl wget unzip`

### Git Configuration
```bash
git config --global user.name "Ton Nom"
git config --global user.email "ton@email.com"
git config --global core.editor "code --wait"
git config --global push.default current
```

### GitHub SSH
```bash
ssh-keygen -t ed25519 -C "email@gmail.com"
cat ~/.ssh/id_ed25519.pub
# Ajouter sur github.com/settings/keys
ssh -T git@github.com
```

### Git Workflow Professionnel
```bash
git checkout -b feat/nom-feature
git add .
git commit -m "feat: description"
git push -u origin feat/nom
# PR sur GitHub → Merge → Supprimer branche
git checkout main && git pull
git branch -d feat/nom
```

### Conventional Commits
- feat: nouvelle fonctionnalité
- fix: correction de bug
- docs: documentation
- chore: maintenance

### Linux Commandes Clés
```bash
uname -a
df -h
free -h
ps aux | head -20
systemctl status <service>
journalctl -u <service> -n 20
crontab -e
chmod +x script.sh
```

### Permissions Linux
- rwx = propriétaire
- r-x = groupe
- r-x = autres
- r=lecture, w=écriture, x=exécution

---

## SEMAINE 02 — Docker

### Installation Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

### Dockerfile
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
EXPOSE 8080
CMD ["python", "app.py"]
```

### Commandes Docker Essentielles
```bash
docker build -t nom:tag .
docker run -d -p 8080:8080 nom
docker ps
docker ps -a
docker logs nom
docker exec -it nom bash
docker stop nom && docker rm nom
docker images
```

### Docker Compose
```bash
docker compose up --build
docker compose down
docker compose logs
```

### Architecture réalisée
Nginx (80) → App Python (8080) → PostgreSQL (5432)

### Bonnes Pratiques
- Toujours utiliser un fichier .env pour les secrets
- Ajouter .env dans .gitignore
- Utiliser healthcheck pour les dépendances
- depends_on avec condition: service_healthy

---

## SEMAINE 03 — GitHub Actions

### Structure
.github/workflows/ci.yml

### Concepts Clés
- workflow : fichier YAML d'automatisation
- job : groupe d'étapes sur un runner
- step : une commande ou action
- trigger : événement déclencheur
- runner : machine virtuelle GitHub

---

## SEMAINE 04 — DevSecOps

### Trivy — Scan d'images Docker
```bash
trivy image python:3.12-slim
```
- Détecte les CVE dans les packages
- Severités : CRITICAL, HIGH, MEDIUM, LOW

### Semgrep — SAST
- Analyse statique du code source
- Détecte patterns dangereux et injections
- Config p/python pour projets Python

### Pipeline Final
Push → Test → SAST → Build → Scan Trivy

---

## Notions Clés

### Sécurité
- Ne jamais committer de secrets
- Scanner les images avant déploiement
- CVE = Common Vulnerabilities and Exposures

### DevOps Mindset
- Tout est code (IaC)
- Automatiser tout ce qui est répétable
- Sécurité intégrée dès le début
- Jamais pousser directement sur main
