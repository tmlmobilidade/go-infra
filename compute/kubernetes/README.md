# Bootstrap Flux CD

## 0. Setup kubectl using OCI CLI

`rm $HOME/.kube/config`

```bash
oci ce cluster create-kubeconfig \
  --cluster-id PASTE_HERE \
  --file $HOME/.kube/config \
  --region eu-frankfurt-1 \
  --token-version 2.0.0
```


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
  --path=compute/kubernetes/prd/cluster \
  --insecure-skip-tls-verify
```

When prompted, enter the GitHub PAT. Flux will:
- Install its controllers into the `flux-system` namespace
- Create a `GitRepository` source for this repo
- Apply everything under `compute/kubernetes/prd/clusters/`, which in turn deploys platform baseline and app HelmReleases


### View Flux logs
`flux logs --insecure-skip-tls-verify`

### Check overall health
`flux check --insecure-skip-tls-verify`


2. Set the 1Password Connect secrets

```bash
kubectl -n onepassword create secret generic op-credentials \
  --from-file=1password-credentials.json=1password-credentials.json
```

```bash
kubectl -n onepassword create secret generic onepassword-token \
  --from-literal=token=<your-connect-token>
```
