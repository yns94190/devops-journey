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
- Scan Trivy réel sur `devops-app:latest` : 57 vulnérabilités (54 HIGH, 3 CRITICAL) avant correction → ajout de `apt-get upgrade` dans `semaine-02/compose/app/Dockerfile` → **44 vulnérabilités (44 HIGH, 0 CRITICAL)** après. Restantes toutes `status: affected` sans patch Debian disponible (util-linux, libacl1, systemd, ncurses) — risque résiduel accepté

### ✅ Semaine 05 — VPS (terminée)
- VPS Oracle Cloud (Free Tier), ARM/aarch64, Oracle Linux 9, user `opc`, accès SSH par clé (IP réelle gardée hors repo, voir `.vps-local.md` non versionné)
- Docker CE installé et actif (`systemctl enable --now docker`)
- `firewalld` configuré : `ssh` + `http` (port 80) autorisés
- App de semaine-02 clonée et déployée sur le VPS (`docker compose up -d --build`)
- Accès externe validé : `curl http://<ip-vps>` → `HTTP 200`, réponse de l'app avec la version PostgreSQL
- Debug réseau : le blocage initial venait de la **Security List ET NSG** OCI (les deux couches doivent autoriser le port 80 en plus du `firewalld` de l'OS) — voir `semaine-05/notes.md`
- Notes : `semaine-05/notes.md`

### ✅ Semaine 06 — Ansible (en cours)
- Ansible installé en local (WSL, via `apt`)
- `semaine-06/ansible/` : `ansible.cfg`, inventaire (`hosts.ini` gitignored + `hosts.ini.example` tracké, pattern identique à `.vps-local.md`), `group_vars/vps.yml`
- Playbook `playbooks/provision.yml` : installe Docker CE + plugin compose (dépôt RHEL officiel) et autorise `http` dans `firewalld` (module `ansible.posix.firewalld`) — idempotent, validé `changed=0` sur rejeu
- Playbook `playbooks/deploy-app.yml` : clone/update du repo sur le VPS, génère `.env` si absent (`creates:`), `docker compose up -d --build`, vérifie la réponse HTTP
- Playbook `playbooks/site.yml` : enchaîne `provision.yml` + `deploy-app.yml` — point d'entrée unique pour reprovisionner le VPS from scratch et déployer
- Notes : `semaine-06/notes.md`
- **Reste à faire :** explorer `ansible-vault` ; envisager `community.docker.docker_compose_v2` pour un statut `changed` fiable sur le déploiement

### ✅ Semaine 07 — Terraform (terminée)
- Terraform 1.16.3 installé en local sans sudo (binaire dans `~/.local/bin`)
- `semaine-07/terraform/` : `versions.tf`, `provider.tf` (auth API Key OCI), `variables.tf`, `main.tf`, `outputs.tf`, `terraform.tfvars.example` tracké / `terraform.tfvars` gitignored, `.terraform.lock.hcl` tracké
- Authentification OCI configurée : paire de clés API générée en local (`~/.oci/`), clé publique ajoutée manuellement dans la console OCI par l'utilisateur (étape non automatisable)
- Première ressource IaC provisionnée avec succès : VCN (`10.0.0.0/16`) + subnet (`10.0.1.0/24`) sur le tenancy OCI — choix délibéré d'une ressource réseau plutôt qu'une instance compute pour ne pas consommer le quota Always Free déjà utilisé par le VPS de semaine-05
- Notes : `semaine-07/notes.md`

### ✅ Semaine 08 — Cloud, suite Terraform (en cours)
- Toujours sur Oracle Cloud (Free Tier) ; code Terraform toujours dans `semaine-07/terraform/` (même state, même VCN) — semaine-08 en est la suite, pas un nouveau stack
- Ajout de `oci_core_internet_gateway.main`, `oci_core_route_table.main` (route `0.0.0.0/0` → IGW) et `oci_core_security_list.main` (ingress SSH 22 + HTTP 80, egress all) dans `main.tf`, subnet mis à jour pour les référencer — `terraform apply` : 3 ajouts, 1 modification, 0 suppression
- VPS existant `devops-server` (semaine-05) importé dans le state (`semaine-07/terraform/instance.tf`, `terraform import`) — **attention** : le compte OCI héberge aussi une instance `jobhunter` (projet perso séparé), une première recherche automatisée avait initialement remonté la mauvaise instance ; toujours vérifier par IP publique avant d'importer
- Après import, `terraform plan` ne montre aucun drift sur la ressource réelle : le bloc `resource` écrit correspond exactement à l'état OCI actuel
- Notes : `semaine-08/notes.md`
- **Reste à faire :** backend distant pour le state (reporté depuis semaine-07), NSG par service, planifier la suite (semaines 09-12)

### ⬜ Semaines 09-12 — Non commencées
- Aucun contenu ni plan détaillé pour l'instant au-delà de la semaine 08

## Règles de travail
- Automatiser tout ce qui est répétable
- Autonomie : corriger seul les erreurs non critiques, demander confirmation si destructif
- Qualité : tester et valider avant de marquer terminé
- Documentation : mettre à jour README.md et CLAUDE.md après chaque étape
- Tokens : réponses courtes, pas de répétitions
- Workflow Git : toujours branche feat/ → PR → merge
- Après chaque tâche : résultat en 1 ligne + prochaine étape

## Prochaine étape suggérée
1. Backend distant pour le state Terraform (OCI Object Storage)
2. Planifier le contenu des semaines 09-12
