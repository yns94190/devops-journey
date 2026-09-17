# CLAUDE.md — DevOps Journey

Parcours DevOps/DevSecOps/Cloud intensif sur 12 semaines, par la pratique.
Environnement : Windows + WSL2 Ubuntu, VS Code (extension WSL), Git/GitHub SSH, Docker, Trivy, Semgrep, pytest.

## État d'avancement

### ✅ Semaine 01 — Linux & Git (terminée)
- WSL2 + Ubuntu installé, VS Code connecté, Git configuré avec SSH GitHub
- Workflow Git pro : branches `feat/nom`, conventional commits (`feat:`, `fix:`, `docs:`, `chore:`), PR → merge → suppression branche
- Linux : permissions (rwx), systemd (`systemctl`), logs (`journalctl`), cron, script `system-check.sh`
- Fichiers : `semaine-01/linux/commandes-essentielles.md`, `semaine-01/notes/progression.md`

### ✅ Semaine 02 — Docker (fonctionnelle, quelques finitions à faire)
- Stack Docker Compose : Nginx (80) → App Python (8080) → PostgreSQL (5432)
- Bonnes pratiques appliquées : `.env` pour les secrets, `healthcheck` sur Postgres, `depends_on: condition: service_healthy`
- Fichiers : `semaine-02/compose/{app,nginx}/`, `docker-compose.yml`, `notes.md`
- **Reste à faire :**
  - Vérifier que `nginx.conf` fait bien le reverse proxy vers `app:8080`
  - `test_app.py` ne teste que des assertions triviales sur une string en dur — à remplacer par un vrai test de l'endpoint HTTP de l'app
  - Doublon à clarifier : `semaine-02/app/` (ancien, juste `app.py` + `Dockerfile`) coexiste avec `semaine-02/compose/app/` — supprimer l'ancien si obsolète
  - Mettre à jour `README.md` racine (ne mentionne encore que semaine-01)

### 🟡 Semaine 03 — GitHub Actions (CI déjà en place, dossier semaine-03/ absent)
- `.github/workflows/ci.yml` existe et fonctionne (jobs `test`, `sast`, `build`, `security-scan`)
- Concepts (workflow, job, step, trigger, runner) documentés seulement dans `docs/mode-operatoire.md`
- **Reste à faire :** créer `semaine-03/` avec des notes structurées, comme pour les semaines 1-2

### 🟡 Semaine 04 — DevSecOps (CI déjà en place, dossier semaine-04/ absent)
- Trivy (scan CVE des images Docker) et Semgrep (SAST, config `p/python`) déjà intégrés dans `ci.yml`
- Pipeline complet : Push → Test → SAST → Build → Scan Trivy
- **Reste à faire :** créer `semaine-04/` avec notes dédiées et documenter les résultats de scan obtenus

### ⬜ Semaines 05-12 — Non commencées
- Aucun contenu ni plan détaillé pour l'instant au-delà de la semaine 04

## Dette / points d'attention
- `.gitignore` contient la ligne `.env` en double (5 fois) — à nettoyer
- Deux dossiers `app` dans `semaine-02` (`semaine-02/app/` et `semaine-02/compose/app/`) à clarifier/fusionner

## Prochaine étape suggérée
1. Finaliser semaine-02 (vrais tests + nettoyage des doublons)
2. Créer les dossiers `semaine-03/` et `semaine-04/` pour matérialiser ce qui existe déjà dans la CI et `docs/mode-operatoire.md`
3. Planifier le contenu des semaines 05-12
