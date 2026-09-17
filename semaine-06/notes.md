# Semaine 06 — Ansible

## Objectif
Automatiser avec Ansible ce qui était fait à la main en semaine-05 : déploiement de l'app (semaine-02) sur le VPS Oracle Cloud.

## Installation
Ansible installé en local dans WSL via `apt` (nécessite un `sudo` interactif, pas automatisable sans mot de passe stocké — installation faite manuellement une fois) :
```bash
sudo apt-get install -y ansible
```

## Structure
```
semaine-06/ansible/
├── ansible.cfg                          # inventaire par défaut, remote_user=opc
├── inventory/
│   ├── hosts.ini                        # IP réelle du VPS (gitignored, cf. .vps-local.md)
│   ├── hosts.ini.example                # tracké, placeholder <IP_VPS>
│   └── group_vars/vps.yml               # repo_url, app_dir, compose_dir
└── playbooks/
    └── deploy-app.yml                   # playbook de déploiement
```

**Pattern IP privée :** même approche que `.vps-local.md` — le fichier avec la vraie IP (`hosts.ini`) est gitignored, seul un `.example` avec placeholder est versionné.

## Playbook `deploy-app.yml`
1. `git` : clone ou met à jour le repo sur le VPS (`update: true`)
2. Génère `.env` **seulement s'il n'existe pas** (`creates:`) — même logique que semaine-05 : secret généré sur la machine cible, jamais transporté
3. `docker compose up -d --build` dans `semaine-02/compose`
4. Vérifie la réponse HTTP locale (module `uri`, retry 5x/3s) et l'affiche

## Exécution
```bash
cd semaine-06/ansible
ansible-playbook playbooks/deploy-app.yml -i inventory/hosts.ini
```

Résultat :
```
TASK [Générer le .env si absent] -> ok (déjà présent, non régénéré)
TASK [Lancer la stack Docker Compose] -> changed
TASK [Vérifier que l'app répond] -> ok
"msg": "Hello from Docker! DB: PostgreSQL 16.15 on aarch64-unknown-linux-musl..."

PLAY RECAP: ok=5 changed=2 unreachable=0 failed=0
```

## Points clés
- Le module `ansible.builtin.git` a besoin de `git` installé côté **cible** (déjà présent sur l'image Oracle Linux)
- `docker compose up -d --build` via le module `command` apparaît toujours `changed` (ce n'est pas un module idempotent-aware comme `community.docker.docker_compose_v2`) — acceptable ici, le comportement réel (rebuild only if changed) reste géré par Docker lui-même
- `creates:` sur la tâche `.env` garantit qu'on ne régénère jamais un mot de passe DB existant en re-jouant le playbook
- `sudo` interactif reste une limite : toute install de paquet système en local (WSL) doit être lancée manuellement par l'utilisateur, pas automatisable par l'agent

## Reste à faire
- Étendre le playbook à l'installation Docker + firewalld (actuellement fait à la main en semaine-05) pour pouvoir reprovisionner le VPS from scratch
- Introduire `ansible-vault` pour un secret si un jour le mot de passe DB doit être piloté depuis le control node plutôt que généré côté cible
