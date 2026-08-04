# Building custom images with Packer

Follow this guide to build custom VM images using Packer on OCI. You will need access to an OCI compartment and the OCI-CLI tool configured in your machine.

## Usage

```
cd servers/valhalla/stg/packer
packer init .
packer validate .
packer build --warn-on-undeclared-var .
```

Copy the resulting image OCID from `packer-manifest.json` into `terraform/variables.tf` (`base_image_ocid`).
