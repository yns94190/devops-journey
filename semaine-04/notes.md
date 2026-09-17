# Semaine 04 — DevSecOps

## Trivy — Scan de vulnérabilités
```bash
trivy image python:3.12-slim
```
- Détecte les CVE (Common Vulnerabilities and Exposures) dans les packages d'une image Docker
- Sévérités : CRITICAL, HIGH, MEDIUM, LOW
- Intégré dans `.github/workflows/ci.yml` (job `security-scan`), filtré sur `CRITICAL,HIGH`

## Semgrep — SAST (analyse statique du code)
- Analyse le code source à la recherche de patterns dangereux et d'injections
- Config utilisée : `p/python`
- Intégré dans `.github/workflows/ci.yml` (job `sast`)

## Pipeline final
Push → Test → SAST → Build → Scan Trivy

## Notions clés
- Ne jamais committer de secrets (utiliser `.env` + `.gitignore`)
- Scanner les images avant tout déploiement
- Sécurité intégrée dès le début du pipeline (« shift left »), pas ajoutée après coup

## Scan concret sur `devops-app:latest`

### Avant correction
```bash
docker build -t devops-app:latest ./semaine-02/compose/app
trivy image --severity HIGH,CRITICAL devops-app:latest
```
Résultat : **57 vulnérabilités** (54 HIGH, 3 CRITICAL) sur la base `debian 13.6` du `python:3.12-slim`.
- 3 CRITICAL : toutes sur `perl-base` (CVE-2026-13221, CVE-2026-42496, CVE-2026-8376)
- Autres correctibles (`status: fixed`) : `gzip` (CVE-2026-41992), `libpcre2-8-0` (3 CVE), `libsqlite3-0` (2 CVE)
- Le reste (`status: affected`, pas de version corrigée) : famille `util-linux` (bsdutils, libblkid1, libmount1, libuuid1, mount, login...), `libacl1`, `libsystemd0`/`libudev1`, `ncurses` — pas de patch Debian disponible au moment du scan, non actionnable via `apt`

### Correction appliquée
Le Dockerfile ne mettait jamais à jour les paquets système hérités de l'image de base. Ajout d'une étape d'upgrade avant l'installation des dépendances Python :
```dockerfile
FROM python:3.12-slim

RUN apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*

WORKDIR /app
...
```

### Après correction
```bash
docker build --no-cache -t devops-app:latest ./semaine-02/compose/app
trivy image --severity HIGH,CRITICAL devops-app:latest
```
Résultat : **44 vulnérabilités (44 HIGH, 0 CRITICAL)** — base passée en `debian 13.7`. Les 3 CRITICAL et 13 HIGH corrigeables ont disparu. Les 44 restantes sont toutes `status: affected` sans version corrigée publiée par Debian à ce jour — risque résiduel accepté, à surveiller (pas une régression du Dockerfile).

### Point clé
`apt-get upgrade` au moment du build capture les derniers correctifs de sécurité Debian disponibles à cet instant — un `docker build` sans cache doit être rejoué périodiquement (ou en CI à chaque run, ce qui est déjà le cas) pour rester à jour, l'image ne se corrige pas toute seule après coup.

## Reste à explorer
- Réévaluer périodiquement les CVE `affected` restantes (util-linux, libacl1, systemd, ncurses) au fil des mises à jour Debian
- Envisager une image de base plus minimale (`python:3.12-alpine` ou `distroless`) pour réduire la surface de paquets système exposés
