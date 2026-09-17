# Semaine 05 — Kubernetes (bases)

## Concepts clés
- **Pod** : plus petite unité déployable, un ou plusieurs containers partageant réseau/stockage
- **Deployment** : gère un ensemble de pods (réplicas, rolling update, rollback)
- **Service** : expose un ensemble de pods (ClusterIP, NodePort, LoadBalancer)
- **ConfigMap** : configuration non sensible injectée dans les pods
- **Secret** : données sensibles (mots de passe, tokens), encodées en base64
- **Namespace** : isolation logique de ressources dans un cluster
- **kubelet / kube-apiserver / etcd** : composants du control plane

## Environnement local
- `kind` ou `minikube` pour un cluster Kubernetes local
- `kubectl` : CLI de pilotage du cluster

## Commandes essentielles
```bash
kubectl get pods
kubectl get deployments
kubectl get services
kubectl describe pod <nom>
kubectl logs <nom>
kubectl exec -it <nom> -- bash
kubectl apply -f fichier.yaml
kubectl delete -f fichier.yaml
kubectl scale deployment <nom> --replicas=3
kubectl rollout status deployment <nom>
kubectl rollout undo deployment <nom>
```

## À réaliser
- Déployer l'app Python de la semaine 02 sur un cluster local (kind/minikube)
- Manifests : `Deployment` (app) + `Service` (ClusterIP ou NodePort) + `ConfigMap`/`Secret` pour les variables DB
- Tester le scaling (`kubectl scale`) et un rolling update

## Bonnes pratiques
- Toujours définir des `requests`/`limits` CPU/mémoire sur les containers
- Ne jamais mettre de secrets en clair dans un manifest versionné
- Utiliser des `readinessProbe` / `livenessProbe` pour la santé des pods
