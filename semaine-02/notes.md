# Semaine 02 — Docker

## Concepts clés
- Image : snapshot immuable d'un environnement
- Container : instance en cours d'exécution d'une image
- Dockerfile : recette pour construire une image
- Docker Compose : orchestration multi-containers

## Commandes essentielles
- `docker build -t nom:tag .` → build une image
- `docker run -d -p 8080:8080 nom` → lance un container
- `docker compose up --build` → lance tous les services
- `docker compose down` → arrête et supprime
- `docker logs nom` → logs d'un container
- `docker exec -it nom bash` → entrer dans un container

## Architecture réalisée
Nginx (80) → App Python (8080) → PostgreSQL (5432)

## Bonnes pratiques
- `.env` pour les secrets, jamais dans le code
- `healthcheck` pour s'assurer que les services sont prêts
- `depends_on` pour gérer l'ordre de démarrage
