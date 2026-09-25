# DevOps Journey 🚀

[![CI Pipeline](https://github.com/yns94190/devops-journey/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/yns94190/devops-journey/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/container-Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Trivy Scan](https://img.shields.io/badge/security-Trivy%20scan-blue)](https://github.com/yns94190/devops-journey/actions/workflows/ci.yml)
[![Semgrep SAST](https://img.shields.io/badge/SAST-Semgrep-purple)](https://github.com/yns94190/devops-journey/actions/workflows/ci.yml)

Parcours DevOps / DevSecOps / Cloud intensif de 12 semaines, construit par la pratique : chaque semaine ajoute une brique (Linux, Docker, CI/CD, sécurité, infra) sur une application réelle, avec un pipeline d'intégration continue qui se renforce au fil du temps.

## Stack technique

| Domaine | Outils |
|---|---|
| OS / Shell | Windows + WSL2 Ubuntu, Bash |
| Versioning | Git, GitHub (branches `feat/`, PR, conventional commits) |
| Containers | Docker, Docker Compose |
| Langage app | Python (`http.server`, `psycopg2`) |
| Base de données | PostgreSQL 16 |
| Reverse proxy | Nginx |
| CI/CD | GitHub Actions |
| Tests | pytest |
| SAST | Semgrep (`p/python`) |
| Scan de vulnérabilités | Trivy |

## Architecture (semaine 02 — Docker)

```
Client
  │
  ▼
┌─────────────┐      ┌──────────────┐      ┌──────────────┐
│   Nginx     │ ───▶ │  App Python  │ ───▶ │  PostgreSQL  │
│  :80        │      │  :8080       │      │  :5432       │
└─────────────┘      └──────────────┘      └──────────────┘
                     (healthcheck + depends_on: service_healthy)
```

- **Nginx** (`:80`) fait office de reverse proxy : il reçoit toutes les requêtes client et les transfère vers l'app sur `app:8080` (config dans `nginx/nginx.conf`).
- **App Python** (`:8080`) est un serveur HTTP minimaliste (`http.server`) qui se connecte à PostgreSQL via `psycopg2` et répond avec la version de la base.
- **PostgreSQL** (`:5432`) stocke les données sur un volume Docker persistant (`postgres_data`), avec un `healthcheck` (`pg_isready`) : l'app ne démarre qu'une fois la base prête (`depends_on: condition: service_healthy`).
- Tous les identifiants (DB, credentials Postgres) sont injectés via `.env`, jamais commités dans le repo.

## Pipeline CI/CD

Déclenché sur chaque `push`/`pull_request` vers `main` (`.github/workflows/ci.yml`) :

```
push/PR → test (pytest) ─┐
          sast (Semgrep) ─┴─▶ build (image Docker) ─▶ security-scan (Trivy)
```

- **test** — exécute les tests unitaires de l'app (`semaine-02/compose/app/test_app.py`)
- **sast** — analyse statique du code source (Semgrep, config `p/python`)
- **build** — build l'image Docker de l'application
- **security-scan** — scanne l'image buildée avec Trivy (CVE `CRITICAL`/`HIGH`)

## Structure du repo

| Semaine | Sujet |
|---|---|
| `semaine-01/` | Linux, Git, administration système |
| `semaine-02/` | Docker & Docker Compose (app 3-tiers) |
| `semaine-03/` | GitHub Actions (CI/CD) |
| `semaine-04/` | DevSecOps (Trivy, Semgrep) |
| `semaine-05/` | VPS |
| `semaine-06/` | Ansible (provisioning & déploiement) |
| `semaine-07/` | Terraform (VCN + subnet) |
| `semaine-08/` | Cloud — Terraform (IGW, route table, security list, import VPS) |
| `semaine-09/` | Kubernetes (k3s) |

Voir [`CLAUDE.md`](./CLAUDE.md) pour le détail de l'avancement semaine par semaine et [`docs/mode-operatoire.md`](./docs/mode-operatoire.md) pour les notes de référence.

## Lancer le projet en local

Prérequis : Docker + Docker Compose installés.

1. **Cloner le repo**
   ```bash
   git clone https://github.com/yns94190/devops-journey.git
   cd devops-journey/semaine-02/compose
   ```
2. **Créer le fichier `.env`** (non versionné) avec les variables attendues :
   ```bash
   cat > .env << 'EOF'
   DB_HOST=db
   DB_NAME=devops
   DB_USER=yanis
   DB_PASSWORD=change-me
   POSTGRES_DB=devops
   POSTGRES_USER=yanis
   POSTGRES_PASSWORD=change-me
   EOF
   ```
3. **Builder et lancer la stack**
   ```bash
   docker compose up --build
   ```
4. **Vérifier que tout tourne**
   ```bash
   docker compose ps        # les 3 services doivent être "healthy"/"running"
   curl http://localhost    # doit retourner "Hello from Docker! DB: PostgreSQL ..."
   ```
5. **Arrêter la stack**
   ```bash
   docker compose down
   ```

## Objectif

Maîtriser DevOps / DevSecOps / Cloud en 3 mois par la pratique.
