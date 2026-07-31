# Valhalla (stg) — Terraform

Valhalla is a routing engine for OpenStreetMap data. It is used to calculate routes and directions for vehicles, pedestrians, and cyclists.


## How to use terraform to deploy the infrastructure

1. Build the packer image: `servers/valhalla/stg/packer`
2. Create a block volume in OCI Console (AD match, >= 100 GiB recommended)
3. Set `base_image_ocid` + `block_volume_ocid` (+ auth) in `terraform.tfvars`
4. `terraform init && terraform apply`

