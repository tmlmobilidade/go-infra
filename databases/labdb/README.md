# ClickHouse

Provisions **1 OCI VM instance** running ClickHouse, single-node and unreplicated.

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

2. **Static IPs**: Choose one free private IP per node within the `pub-cmet` subnet and add to
   `terraform.tfvars`.

3. **Networking team**: Ensure the existing Security List allows inbound TCP on these ports from your clients:
   - `8123` — ClickHouse HTTP
   - `9000` — ClickHouse native TCP
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

## Creating a Table

```sql
CREATE TABLE events (
    id   UUID,
    ts   DateTime,
    data String
) ENGINE = MergeTree
ORDER BY (ts, id);
```

> **No replication.** This deployment runs a single node with no Keeper, no ZooKeeper client
> config, no `remote_servers` and no replica macros — a lone node gains nothing from a
> single-member Raft quorum and pays for it in fsyncs and constant connection timeouts in the
> error log. As a result `ReplicatedMergeTree` and `ON CLUSTER` DDL are unavailable: both
> require a Keeper quorum. Adding replicas means restoring `keeper.xml`, `zookeeper.xml`,
> `macros.xml` and `cluster.xml` in `cloud-init.yaml`, plus ports `9009`, `2181` and `9444` in
> `packer/init/firewall.sh`. Durability today rests on the block volume and its backups, not on
> a second copy of the data.

## Tuning

`terraform/templates/cloud-init.yaml` writes the ClickHouse configuration, but cloud-init only
runs on first boot. Changing it affects newly provisioned nodes; to apply it to a node that is
already running, write the same file over SSH and either reload or restart.

| File | Purpose | Applying it |
|---|---|---|
| `users.d/tuning.xml` | Memory limits, async insert batching, insert threads | `SYSTEM RELOAD CONFIG` |
| `config.d/tuning.xml` | Server memory ratio, Prometheus endpoint | restart required |
| `config.d/logs.xml` | System log retention / disabled tables | restart required |
| `users.d/logging.xml` | Disables profiler sampling | `SYSTEM RELOAD CONFIG` |

Cache sizes (`mark_cache_size`, `uncompressed_cache_size`) are intentionally left at their
defaults. Note that `uncompressed_cache_size` only has an effect for queries run with
`use_uncompressed_cache = 1`, which is off by default.

### System log cleanup

Changing the definition of an existing system table makes ClickHouse rename the old table to
`<name>_<n>` on restart. Renamed tables stop merging immediately but keep their disk space
until dropped. Find them with:

```sql
SELECT table, formatReadableSize(sum(bytes_on_disk)) AS size
FROM system.parts
WHERE active AND database = 'system' AND match(table, '_\d+$')
GROUP BY table ORDER BY sum(bytes_on_disk) DESC;
```

`max_table_size_to_drop` is 50GB and the override flag is consumed by each `DROP`, so recreate
it on the host before every large drop:

```bash
sudo touch /opt/app/persistent-data/data/flags/force_drop_table \
  && sudo chmod 666 /opt/app/persistent-data/data/flags/force_drop_table
```

### Verifying

```sql
-- Disk usage per database
SELECT database, formatReadableSize(sum(bytes_on_disk))
FROM system.parts WHERE active GROUP BY database;

-- Rows per async insert flush (should be thousands, not tens)
SELECT avg(rows), avg(bytes) FROM system.asynchronous_insert_log
WHERE event_time > now() - INTERVAL 1 HOUR;
```

## Outputs

| Output | Description |
|---|---|
| `instance_public_ips` | Public IP of the node |
| `instance_private_ips` | Private IPs of the node |
| `clickhouse_http_urls` | HTTP interface URLs |
| `clickhouse_tcp_dsns` | Native TCP endpoints |
| `ssh_commands` | SSH connection commands |
