### To start


1. From VSCode:
You'll need a Github PAT

flux bootstrap github \
  --owner=tmlmobilidade \
  --repository=go-infra \
  --branch=main \
  --path=compute/kubernetes/clusters/prd \
  --insecure-skip-tls-verify


2. Set the 1Password secret

`kubectl create namespace onepassword`

`kubectl -n onepassword create secret generic onepassword-service-account-token --from-literal=token=PASTE_HERE`
