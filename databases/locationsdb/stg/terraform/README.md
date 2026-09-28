# LocationsDB Terraform (prd)

Deploys one VM from the Packer LocationsDB image, attaches a pre-created block volume, and runs cloud-init (PostGIS + background Europe OSM import).
Block volume recommend ≥ 500 GiB (Europe PBF ~25GB + flat-nodes + PostGIS).

See `../packer/README.md` for image build and runtime paths.

```bash
cp example.tfvars terraform.tfvars   # fill values
terraform init
terraform apply
```
