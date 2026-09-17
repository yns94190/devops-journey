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

## Reste à explorer
- Résultats concrets d'un scan Trivy sur l'image de l'app (`devops-app:latest`)
- Correction des éventuelles CVE trouvées
