# MongoDB Replica Set

Provisions **3 OCI VM instances** running MongoDB in a standard **Replica Set** (`rs0` by default). One node is elected primary; the other two are secondaries. All nodes use the same shared keyfile for internal authentication.

## Architecture

```
  Node 1 — PRIMARY         Node 2 — SECONDARY       Node 3 — SECONDARY
  ┌────────────────┐        ┌────────────────┐        ┌────────────────┐
  │ mongod         │◄──────►│ mongod         │◄──────►│ mongod         │
  │ --replSet rs0  │        │ --replSet rs0  │        │ --replSet rs0  │
  └────────────────┘        └────────────────┘        └────────────────┘
   private_ips[0]            private_ips[1]            private_ips[2]
   (priority 2)              (priority 1)              (priority 1)
```

- **Replication**: Standard MongoDB replica set — writes go to primary, reads can go to any node.
- **Keyfile auth**: All 3 nodes share the same keyfile (injected via Terraform variable) for inter-member authentication.
- **Initialization**: Node 0 runs `rs.initiate()` on first boot with all 3 IPs pre-configured. Secondaries join automatically.
- **Networking**: This module creates **zero** networking resources. Instances attach to the existing `pub-cmet` subnet.

## Prerequisites

1. **Generate a keyfile** (one-time, keep safe — same value used for all 3 nodes):
   ```bash
   openssl rand -base64 756
   ```
   Paste the output into `terraform.tfvars` as `mongodb_keyfile`.

2. **Packer image**: Build the base image first (or leave `base_image_ocid` to fall back to raw Ubuntu):
   ```bash
   cd packer/
   packer init .
   packer build -var-file=../terraform/terraform.tfvars .
   ```

3. **Static IPs**: Choose 3 free private IPs within the `pub-cmet` subnet and add to `terraform.tfvars`.

4. **Networking team**: Ensure the existing Security List allows inbound TCP on:
   - `27017` — MongoDB (between nodes and from clients)
   - `22`    — SSH

## Usage

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — fill in credentials, private_ips, and mongodb_keyfile
terraform init
terraform plan
terraform apply
```

## Verifying the Replica Set

SSH into node 1 and run:
```bash
docker exec -it mongodb mongosh \
  -u admin -p '<password>' \
  --authenticationDatabase admin \
  --eval "rs.status()"
```

All 3 members should appear — one `PRIMARY`, two `SECONDARY`.

## Connection String

```
mongodb://admin:<password>@<ip1>:27017,<ip2>:27017,<ip3>:27017/?replicaSet=rs0&authSource=admin
```

The `replica_set_dsn` Terraform output provides this string with the actual IPs.

## Outputs

| Output | Description |
|---|---|
| `instance_public_ips` | Public IPs of all 3 nodes |
| `instance_private_ips` | Private IPs of all 3 nodes |
| `mongodb_dsns` | Per-node connection strings |
| `replica_set_dsn` | Full replica set connection string |
| `ssh_commands` | SSH connection commands |
