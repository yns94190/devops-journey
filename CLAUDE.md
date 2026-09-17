# CLAUDE.md — DevOps Journey

Parcours DevOps/DevSecOps/Cloud intensif sur 12 semaines, par la pratique.
Environnement : Windows + WSL2 Ubuntu, VS Code (extension WSL), Git/GitHub SSH, Docker, Trivy, Semgrep, pytest.

## État d'avancement

### ✅ Semaine 01 — Linux & Git (terminée)
- WSL2 + Ubuntu installé, VS Code connecté, Git configuré avec SSH GitHub
- Workflow Git pro : branches `feat/nom`, conventional commits (`feat:`, `fix:`, `docs:`, `chore:`), PR → merge → suppression branche
- Linux : permissions (rwx), systemd (`systemctl`), logs (`journalctl`), cron, script `system-check.sh`
- Fichiers : `semaine-01/linux/commandes-essentielles.md`, `semaine-01/notes/progression.md`

### ✅ Semaine 02 — Docker (terminée)
- Stack Docker Compose : Nginx (80, reverse proxy vérifié vers `app:8080`) → App Python (8080) → PostgreSQL (5432)
- Bonnes pratiques appliquées : `.env` pour les secrets, `healthcheck` sur Postgres, `depends_on: condition: service_healthy`
- `test_app.py` fait un vrai test HTTP : démarre le serveur sur un port éphémère, mocke `app.get_db` (succès + erreur DB) et vérifie le statut/le corps de la réponse
- Fichiers : `semaine-02/compose/{app,nginx}/`, `docker-compose.yml`, `notes.md`

### ✅ Semaine 03 — GitHub Actions (terminée)
- `.github/workflows/ci.yml` existe et fonctionne (jobs `test`, `sast`, `build`, `security-scan`)
- Concepts (workflow, job, step, trigger, runner) documentés dans `semaine-03/notes.md` et `docs/mode-operatoire.md`

### ✅ Semaine 04 — DevSecOps (terminée)
- Trivy (scan CVE des images Docker) et Semgrep (SAST, config `p/python`) déjà intégrés dans `ci.yml`
- Pipeline complet : Push → Test → SAST → Build → Scan Trivy
- Notes : `semaine-04/notes.md`
- **Reste à faire :** documenter les résultats concrets d'un scan Trivy sur `devops-app:latest` et corriger les CVE trouvées

### ✅ Semaine 05 — VPS (terminée)
- VPS Oracle Cloud (Free Tier), ARM/aarch64, Oracle Linux 9, user `opc`, accès SSH par clé (IP réelle gardée hors repo, voir `.vps-local.md` non versionné)
- Docker CE installé et actif (`systemctl enable --now docker`)
- `firewalld` configuré : `ssh` + `http` (port 80) autorisés
- App de semaine-02 clonée et déployée sur le VPS (`docker compose up -d --build`)
- Accès externe validé : `curl http://<ip-vps>` → `HTTP 200`, réponse de l'app avec la version PostgreSQL
- Debug réseau : le blocage initial venait de la **Security List ET NSG** OCI (les deux couches doivent autoriser le port 80 en plus du `firewalld` de l'OS) — voir `semaine-05/notes.md`
- Notes : `semaine-05/notes.md`

### ⬜ Semaines 06-12 — Non commencées
- Aucun contenu ni plan détaillé pour l'instant au-delà de la semaine 05

## Règles de travail
- Automatiser tout ce qui est répétable
- Autonomie : corriger seul les erreurs non critiques, demander confirmation si destructif
- Qualité : tester et valider avant de marquer terminé
- Documentation : mettre à jour README.md et CLAUDE.md après chaque étape
- Tokens : réponses courtes, pas de répétitions
- Workflow Git : toujours branche feat/ → PR → merge
- Après chaque tâche : résultat en 1 ligne + prochaine étape

## Prochaine étape suggérée
1. Documenter un scan Trivy réel (semaine-04)
2. Planifier le contenu de la semaine 06 et suivantes
