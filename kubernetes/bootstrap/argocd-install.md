# Bootstrap Argo CD

## 1. Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## 2. Create GitHub token secret

Required for the PR preview generators to watch the `tmlmobilidade/go` repo:

```bash
kubectl create secret generic github-token \
  --namespace argocd \
  --from-literal=token=<GITHUB_PAT>
```

## 3. Create shared module secrets

Each module namespace needs its shared secrets. For the `auth` module:

```bash
kubectl create namespace auth
kubectl create secret generic auth-shared-secrets \
  --namespace auth \
  --from-env-file=<path-to-auth-env-file>
```

## 4. Deploy root Application (app-of-apps)

This single Application manages all other Applications and ApplicationSets:

```bash
kubectl apply -f root-application.yml
```

Argo CD will automatically discover and sync all apps under `kubernetes/apps/`.