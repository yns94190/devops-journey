# DevOps Journey 🚀

[![CI Pipeline](https://github.com/yns94190/devops-journey/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/yns94190/devops-journey/actions/workflows/ci.yml)
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

Secrets injectés via `.env` (jamais commités), volume persistant pour les données Postgres.

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

Voir [`CLAUDE.md`](./CLAUDE.md) pour le détail de l'avancement semaine par semaine et [`docs/mode-operatoire.md`](./docs/mode-operatoire.md) pour les notes de référence.

## Lancer le projet en local

```bash
cd semaine-02/compose
docker compose up --build
# App accessible via Nginx sur http://localhost
```

## Objectif

Maîtriser DevOps / DevSecOps / Cloud en 3 mois par la pratique.
