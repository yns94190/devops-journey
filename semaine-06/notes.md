# Semaine 06 — Ansible

## Objectif
Automatiser avec Ansible ce qui était fait à la main en semaine-05 : provisioning du VPS (Docker + firewalld) et déploiement de l'app (semaine-02).

## 1. Installation Ansible
En local, dans WSL, via `apt` (nécessite un `sudo` interactif — pas automatisable sans mot de passe stocké, installation faite manuellement une fois) :
```bash
sudo apt-get install -y ansible
ansible --version   # core 2.20.1
```
Collections utilisées, déjà fournies par le paquet `ansible` (méta-paquet) :
- `ansible.posix` (module `firewalld`)
- `community.general`

## 2. Structure du projet
```
semaine-06/ansible/
├── ansible.cfg                          # inventaire par défaut, remote_user=opc
├── inventory/
│   ├── hosts.ini                        # IP réelle du VPS (gitignored)
│   ├── hosts.ini.example                # tracké, placeholder <IP_VPS>
│   └── group_vars/vps.yml               # repo_url, app_dir, compose_dir
└── playbooks/
    ├── provision.yml                    # Docker + firewalld
    ├── deploy-app.yml                   # déploiement de l'app
    └── site.yml                         # provision + deploy enchaînés
```

## 3. Inventaire VPS
**Pattern IP privée :** même approche que `.vps-local.md` (racine du repo) — le fichier avec la vraie IP (`hosts.ini`) est gitignored, seul un `.example` avec placeholder est versionné.

`inventory/hosts.ini` (local, non versionné) :
```ini
[vps]
oracle-vps ansible_host=<IP_VPS> ansible_user=opc
```

`inventory/group_vars/vps.yml` (tracké, pas de secret) :
```yaml
repo_url: https://github.com/yns94190/devops-journey.git
app_dir: /home/opc/devops-journey
compose_dir: "{{ app_dir }}/semaine-02/compose"
```

Prérequis validé sur le VPS avant le premier run : `opc` a un sudo sans mot de passe (`sudo -n true`) — image Oracle Linux par défaut, permet à `provision.yml` (qui utilise `become: true`) de tourner sans interaction.

## 4. Playbook `provision.yml`
Automatise l'installation manuelle de la semaine-05 (Docker CE + firewalld) pour pouvoir reprovisionner le VPS from scratch :
1. Installe `dnf-utils`
2. Ajoute le dépôt officiel Docker RHEL (`get_url` vers `/etc/yum.repos.d/docker-ce.repo`)
3. Installe `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin` (module `dnf`, idempotent)
4. Active et démarre le service Docker (module `systemd`)
5. Ajoute `opc` au groupe `docker`
6. Autorise le service `http` dans `firewalld` (module `ansible.posix.firewalld`)

`become: true` au niveau du play.

## 5. Playbook `deploy-app.yml`
1. `git` : clone ou met à jour le repo sur le VPS (`update: true`)
2. Génère `.env` **seulement s'il n'existe pas** (`creates:`) — secret généré sur la machine cible, jamais transporté en clair (même logique que semaine-05)
3. `docker compose up -d --build` dans `semaine-02/compose`
4. Vérifie la réponse HTTP locale (module `uri`, retry 5x/3s) et l'affiche

## 6. Playbook `site.yml`
Enchaîne `provision.yml` puis `deploy-app.yml` via `import_playbook` — point d'entrée unique pour reconstruire le VPS et déployer l'app.

## 7. Commandes utilisées
```bash
cd semaine-06/ansible

# Vérifier la connectivité et le sudo sans mot de passe
ssh -o BatchMode=yes opc@<IP_VPS> 'sudo -n true && echo OK'

# Provisioning seul (Docker + firewalld)
ansible-playbook playbooks/provision.yml -i inventory/hosts.ini

# Déploiement seul (app)
ansible-playbook playbooks/deploy-app.yml -i inventory/hosts.ini

# Provisioning + déploiement en une commande
ansible-playbook playbooks/site.yml -i inventory/hosts.ini
```

## 8. Résultats obtenus

### `deploy-app.yml` (premier run)
```
TASK [Générer le .env si absent] -> ok (déjà présent, non régénéré)
TASK [Lancer la stack Docker Compose] -> changed
TASK [Vérifier que l'app répond] -> ok
"msg": "Hello from Docker! DB: PostgreSQL 16.15 on aarch64-unknown-linux-musl..."

PLAY RECAP: ok=5 changed=2 unreachable=0 failed=0
```

### `provision.yml` — validation idempotence (VPS déjà configuré)
```
PLAY RECAP: oracle-vps : ok=7 changed=0 unreachable=0 failed=0
```
Aucun changement détecté sur un rejeu — confirme que le playbook peut être exécuté sans effet de bord, y compris pour reprovisionner un VPS neuf from scratch.

### `site.yml` (provision + deploy, VPS déjà provisionné)
```
PLAY RECAP: oracle-vps : ok=12 changed=2 unreachable=0 failed=0
```
Les 2 `changed` viennent uniquement de `deploy-app.yml` (`git update` + `docker compose up -d --build`) ; la partie provisioning reste à `changed=0`.

## 9. Scan Trivy & correction des CVE
Réalisé pendant la semaine 06 pour clore le reliquat de la semaine 04 (scan de `devops-app:latest`, image construite depuis `semaine-02/compose/app`).

- **Avant correction** : 57 vulnérabilités (54 HIGH, 3 CRITICAL) — base `debian 13.6` du `python:3.12-slim`, les 3 CRITICAL toutes sur `perl-base`
- **Correction** : ajout de `RUN apt-get update && apt-get upgrade -y` dans `semaine-02/compose/app/Dockerfile`
- **Après correction** : 44 vulnérabilités (44 HIGH, **0 CRITICAL**) — base passée en `debian 13.7`
- Restantes : toutes `status: affected`, sans version corrigée publiée par Debian (util-linux, libacl1, systemd, ncurses) — risque résiduel accepté, pas une régression du Dockerfile

Détail complet (tableau CVE avant/après, commandes `trivy image`) : voir `semaine-04/notes.md`.

## Points clés
- Le module `ansible.builtin.git` a besoin de `git` installé côté **cible** (déjà présent sur l'image Oracle Linux)
- `docker compose up -d --build` via le module `command` apparaît toujours `changed` (pas un module idempotent-aware comme `community.docker.docker_compose_v2`) — acceptable ici, le comportement réel (rebuild only if changed) reste géré par Docker lui-même
- `creates:` sur la tâche `.env` garantit qu'on ne régénère jamais un mot de passe DB existant en re-jouant le playbook
- `sudo` interactif reste une limite : toute install de paquet système en local (WSL) doit être lancée manuellement par l'utilisateur, pas automatisable par l'agent — côté VPS, le sudo sans mot de passe d'`opc` contourne le problème pour `become: true`

## Reste à faire
- Introduire `ansible-vault` pour un secret si un jour le mot de passe DB doit être piloté depuis le control node plutôt que généré côté cible
- Envisager `community.docker.docker_compose_v2` pour un statut `changed` fiable sur le déploiement
- Réévaluer périodiquement les CVE `affected` restantes (util-linux, libacl1, systemd, ncurses) au fil des mises à jour Debian
