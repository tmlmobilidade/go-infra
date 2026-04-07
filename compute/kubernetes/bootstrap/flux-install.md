# Bootstrap Flux CD

## 1. Install Flux CLI

```bash
brew install fluxcd/tap/flux
```

## 2. Pre-check cluster compatibility

```bash
flux check --pre
```

## 3. Bootstrap Flux onto the cluster

This installs Flux components and sets up the Git connection. Replace `<GITHUB_PAT>` with a personal access token that has repo access to `tmlmobilidade/go-infra`.

```bash
flux bootstrap github \
  --owner=tmlmobilidade \
  --repository=go-infra \
  --branch=production \
  --path=compute/kubernetes/clusters/production \
  --insecure-skip-tls-verify
#  --personal=false
#  --token-auth
```

When prompted, enter the GitHub PAT. Flux will:
- Install its controllers into the `flux-system` namespace
- Create a `GitRepository` source for this repo
- Apply everything under `kubernetes/clusters/production/`, which in turn deploys infrastructure sources and app HelmReleases

## 4. Create shared module secrets

Each module namespace needs its shared secrets. For the `auth` module:

```bash
kubectl create namespace auth-prd
kubectl create secret generic auth-shared-secrets \
  --namespace auth-prd \
  --from-env-file=<path-to-auth-env-file>
```

## 5. Verify

```bash
flux get kustomizations
flux get helmreleases -n auth-prd
kubectl get pods -n auth-prd
```

## Useful commands

```bash
# Force reconciliation
flux reconcile kustomization apps-production

# View Flux logs
flux logs

# Check overall health
flux check
```
