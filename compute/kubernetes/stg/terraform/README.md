# OKE Cluster — Production

Terraform deployment for the OCI Kubernetes Engine (OKE) managed cluster in the `go-stg` compartment.

## Resources Created

| Resource | Description |
|----------|-------------|
| `oci_containerengine_cluster` | OKE managed cluster with Flannel overlay CNI |
| `oci_containerengine_node_pool` | Worker node pool (3× VM.Standard.E4.Flex) |

This module creates **zero** networking resources. The cluster attaches to the existing VCN and subnets.

## Usage

```bash
# 1. Copy and fill in the variables
cp example.tfvars terraform.tfvars

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Apply
terraform apply

# 5. Get kubeconfig (shown in outputs after apply)
oci ce cluster create-kubeconfig --cluster-id <cluster-id> --region eu-frankfurt-1 --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT
```

## Variables

The `kubernetes_version` and `node_image_ocid` variables auto-discover the latest available values if left empty.