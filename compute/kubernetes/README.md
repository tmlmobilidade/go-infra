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
  --branch=main \
  --path=compute/kubernetes/clusters/prd \
  --insecure-skip-tls-verify
```

When prompted, enter the GitHub PAT. Flux will:
- Install its controllers into the `flux-system` namespace
- Create a `GitRepository` source for this repo
- Apply everything under `compute/kubernetes/clusters/prd/`, which in turn deploys infrastructure sources and app HelmReleases


### View Flux logs
`flux logs --insecure-skip-tls-verify`

### Check overall health
`flux check --insecure-skip-tls-verify`


2. Set the 1Password secret

`kubectl -n onepassword create secret generic onepassword-service-account-token --from-literal=token=PASTE_HERE`
