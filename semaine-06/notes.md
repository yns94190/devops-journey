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

## Playbook `provision.yml`
Automatise l'installation manuelle de la semaine-05 (Docker CE + firewalld) pour pouvoir reprovisionner le VPS from scratch :
1. Installe `dnf-utils`
2. Ajoute le dépôt officiel Docker RHEL (`get_url` vers `/etc/yum.repos.d/docker-ce.repo`)
3. Installe `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-compose-plugin` (module `dnf`, idempotent)
4. Active et démarre le service Docker (module `systemd`)
5. Ajoute `opc` au groupe `docker`
6. Autorise le service `http` dans `firewalld` (module `ansible.posix.firewalld`, déjà présent avec le paquet `ansible` d'Ubuntu)

`become: true` au niveau du play — testé avec le sudo sans mot de passe déjà configuré sur `opc` (image Oracle Linux par défaut).

## Playbook `site.yml`
Enchaîne `provision.yml` puis `deploy-app.yml` via `import_playbook` — un seul point d'entrée pour reconstruire le VPS et déployer l'app :
```bash
ansible-playbook playbooks/site.yml -i inventory/hosts.ini
```

## Validation idempotence
Deux exécutions consécutives de `provision.yml` sur le VPS déjà configuré :
```
PLAY RECAP: ok=7 changed=0 ...
```
Aucun changement détecté — confirme que le playbook peut être rejoué sans effet de bord.

`site.yml` (provision + deploy) sur le VPS déjà provisionné :
```
PLAY RECAP: ok=12 changed=2 ...
```
Les 2 `changed` viennent de `deploy-app.yml` (`git update` + `docker compose up -d --build`, ce dernier n'étant pas idempotent-aware côté Ansible cf. plus haut) — la partie provisioning reste à `changed=0`.

## Reste à faire
- Introduire `ansible-vault` pour un secret si un jour le mot de passe DB doit être piloté depuis le control node plutôt que généré côté cible
- Éventuellement remplacer le `command: docker compose up -d --build` par `community.docker.docker_compose_v2` pour un statut `changed` plus fiable
