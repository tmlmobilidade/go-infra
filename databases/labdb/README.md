# ClickHouse Replica Set

Provisions **1 OCI VM instance** running ClickHouse.

## Architecture

```
  Node 1 (labdb-1)      
  ┌────────────────┐       
  │ server         │
  └────────────────┘        
   private_ips[0]           
```

## Prerequisites

1. **Packer image**: Build the base image first (or leave `base_image_ocid` to fall back to raw Ubuntu):
   ```bash
   cd packer/
   packer init .
   packer build -var-file=../terraform/terraform.tfvars .
   ```

2. **Static IPs**: Choose 3 free private IPs within the `pub-cmet` subnet and add to `terraform.tfvars`.

3. **Networking team**: Ensure the existing Security List allows inbound TCP on these ports from your clients:
   - `8123` — ClickHouse HTTP
   - `9000` — ClickHouse native TCP
   - `9009` — Interserver replication (between the 3 nodes, i.e. within the subnet)
   - `2181` — Keeper client / ZooKeeper-compatible (between the 3 nodes)
   - `9444` — Keeper Raft (between the 3 nodes)
   - `22`   — SSH

## Usage

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in credentials and private_ips
terraform init
terraform plan
terraform apply
```

## Creating a Replicated Table

```sql
CREATE TABLE events ON CLUSTER 'default_cluster' (
    id   UUID,
    ts   DateTime,
    data String
) ENGINE = ReplicatedMergeTree('/clickhouse/tables/{shard}/{table}', '{replica}')
ORDER BY (ts, id);
```

## Outputs

| Output | Description |
|---|---|
| `instance_public_ips` | Public IP of the node |
| `instance_private_ips` | Private IPs of the node |
| `clickhouse_http_urls` | HTTP interface URLs |
| `clickhouse_tcp_dsns` | Native TCP endpoints |
| `ssh_commands` | SSH connection commands |
