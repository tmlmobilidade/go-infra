# Building custom images with Packer

Follow this guide to build custom VM images using Packer on OCI. You will need access to an OCI compartment and the OCI-CLI tool configured in your machine.


## Usage
Open a new terminal window and change the shell into this directory:
```
cd ./infra/clickhouse/packer
```

Initialize the packer module and validate the configuration files:
```
packer init .
packer validate .
packer build .
```