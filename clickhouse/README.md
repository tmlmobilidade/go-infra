# ClickHouse Replica Set

Provisions **3 OCI VM instances** running ClickHouse in a replicated configuration using **ClickHouse Keeper** (embedded ZooKeeper-compatible consensus service). Each node runs a single Docker container that embeds both `clickhouse-server` and `clickhouse-keeper`.

## Architecture

```
  Node 1 (replica-1)       Node 2 (replica-2)       Node 3 (replica-3)
  ┌────────────────┐        ┌────────────────┐        ┌────────────────┐
  │ clickhouse-    │        │ clickhouse-    │        │ clickhouse-    │
  │ server         │◄──────►│ server         │◄──────►│ server         │
  │ + keeper       │        │ + keeper       │        │ + keeper       │
  └────────────────┘        └────────────────┘        └────────────────┘
   private_ips[0]            private_ips[1]            private_ips[2]
```

- **Replication**: Uses `ReplicatedMergeTree` tables. Tables must be created with the macro-based path (auto-populated via `{cluster}`, `{shard}`, `{replica}` macros).
- **Keeper quorum**: All 3 nodes form a 3-member Raft quorum — can tolerate 1 node failure.
- **No sharding**: All 3 nodes are replicas of a single shard (shard 01).
- **Networking**: This module creates **zero** networking resources. Instances attach to the existing `pub-cmet` subnet.

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
| `instance_public_ips` | Public IPs of all 3 nodes |
| `instance_private_ips` | Private IPs of all 3 nodes |
| `clickhouse_http_urls` | HTTP interface URLs |
| `clickhouse_tcp_dsns` | Native TCP endpoints |
| `ssh_commands` | SSH connection commands |
