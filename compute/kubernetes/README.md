# Bootstrap Flux CD

This module contains the pieces needed to deploy a full cluster configuration and application workloads.. It includes the cluster resources, platform baseline, and application HelmReleases.

Uses 1Password Connect to manage secrets, and the configuration for that is included in this module as well. The cluster is deployed in OCI, and the configuration files are customized to that environment.

This Terraform project provisions an Oracle Cloud Infrastructure (OCI) Kubernetes environment using:
- oci_containerengine_cluster
- oci_containerengine_virtual_node_pool

The deployment creates an Oracle Kubernetes Engine (OKE) cluster and attaches a Virtual Node Pool that provides serverless-style Kubernetes worker capacity managed by OCI.

This environment uses Flux CD to monitors Git repository and synchronizes Kubernetes manifests into the Oracle Kubernetes Engine (OKE) cluster.

```bash
Terraform
   │
   ▼
OKE Cluster
   │
   ├── Flux CD
   │      │
   │      ▼
   │   Helm Charts
   │
   └── Running Applications
```


## 0. Setup kubectl using OCI CLI

`rm $HOME/.kube/config`

```bash
oci ce cluster create-kubeconfig \
  --cluster-id PASTE_HERE \
  --file $HOME/.kube/config \
  --region eu-frankfurt-1 \
  --token-version 2.0.0
```

To setup the tunnel:

```bash
ssh -N -L 6443:K8S_API_ENDPOINT:6443 ubuntu@go-prd-jumpserver.tmlmobilidade.pt
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
- Apply everything under `compute/kubernetes/prd/cluster/`, which in turn deploys platform baseline and app HelmReleases


### View Flux logs
`flux logs --insecure-skip-tls-verify`

### Check overall health
`flux check --insecure-skip-tls-verify`


2. Set the 1Password Connect secrets, using the jumpserver

```bash
kubectl -n onepassword create secret generic op-credentials \
  --from-file=1password-credentials.json=1password-credentials.json \
  --dry-run=client -o yaml | kubectl apply -f -
```

```bash
kubectl -n onepassword create secret generic onepassword-token \
  --from-literal=token=<your-connect-token> \
  --dry-run=client -o yaml | kubectl apply -f -
```
