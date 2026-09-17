# Semaine 03 — GitHub Actions

## Concepts clés
- **Workflow** : fichier YAML d'automatisation (`.github/workflows/*.yml`)
- **Job** : groupe d'étapes exécutées sur un runner
- **Step** : une commande ou une action
- **Trigger** : événement déclencheur (`push`, `pull_request`, ...)
- **Runner** : machine virtuelle GitHub qui exécute les jobs

## Pipeline réalisé
Fichier : `.github/workflows/ci.yml`

Jobs :
- `test` → installe les dépendances Python et lance `pytest` sur `semaine-02/compose/app/test_app.py`
- `sast` → analyse statique du code avec Semgrep (config `p/python`)
- `build` → build de l'image Docker de l'app (dépend de `test` et `sast`)
- `security-scan` → scan de l'image buildée avec Trivy (dépend de `build`)

Triggers : `push` et `pull_request` sur la branche `main`

## Bonnes pratiques
- Jobs indépendants en parallèle (`test`, `sast`), jobs dépendants avec `needs`
- Ne jamais pousser directement sur `main` — passer par une PR pour déclencher la CI
