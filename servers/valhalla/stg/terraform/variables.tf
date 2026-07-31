# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-stg-valhalla"
}


# # #
# OCI AUTHENTICATION

variable "tenancy_ocid" {
	type = string
	description = "The OCID of the Oracle Cloud Infrastructure tenancy."
}

variable "user_ocid" {
	type = string
	description = "The OCID of the OCI user (e.g. tiago.macedo) used for API authentication."
}

variable "fingerprint" {
	type = string
	description = "The fingerprint of the API key."
}

variable "private_key_path" {
	type = string
	description = "The file path to the private key for OCI API authentication."
}

variable "ssh_authorized_keys_path" {
	type = string
	description = "The file path to the SSH authorized keys to allow instance access."
}


# # #
# OCI PLACEMENT

variable "compartment_ocid" {
	type = string
	description = <<-EOT
	The OCID of the compartment where resources will be created in.
	Current compartment is set to: go-stg
	EOT
	default = "ocid1.compartment.oc1..aaaaaaaanljo4qhg4wnwjpul5seazrticeyswmx5zt7f64ekfewpr6y6mbva"
}

variable "availability_domain" {
	type = string
	description = "The availability domain where resources will be created (e.g. 'LUDo:EU-FRANKFURT-1-AD-1')."
	default = "LUDo:EU-FRANKFURT-1-AD-1"
}

variable "region" {
	type = string
	description = "The OCI region to deploy resources in."
	default = "eu-frankfurt-1"
}


# # #
# NETWORKING

variable "subnet_ocid" {
	type = string
	description = <<-EOT
	OCID of the existing subnet to attach the instance to.
	Networking is managed externally — this module creates no VCN, subnet,
	IGW, route table, security list, or NSG.
	EOT
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaabxgcifumk7or4z5kbdj6l6tkox3xqzpnmvhmq3l5hruveil4ze3q"
}

variable "private_ip" {
	type = string
	description = <<-EOT
	Static private IP for the Valhalla instance.
	Must be free within the public subnet — verify in OCI Console before applying.
	EOT
	default = "10.91.101.10"
}


# # #
# VM SHAPE

variable "base_image_ocid" {
	type = string
	description = "OCID of the Packer-built Valhalla image. Set after packer build."
	default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaavkw2cewurojmwijrtf5d3yanykmzegoyn3zonfcmglzaejjmq5ha"
}

variable "vm_shape" {
	type = string
	description = "The shape of the VM."
	default = "VM.Standard.A1.Flex"
}

variable "vm_ocpus" {
	type = number
	description = "Number of OCPUs (match image ENV server_threads=4)."
	default = 4
}

variable "vm_memory_in_gbs" {
	type = number
	description = "Memory in GBs (tile build needs headroom)."
	default = 32
}

variable "boot_volume_size_in_gbs" {
	type = number
	description = "Boot volume size in GBs."
	default = 50
}


# # #
# STORAGE

variable "block_volume_ocid" {
	type = string
	description = <<-EOT
	OCID of an existing block volume for Valhalla custom_files (PBF + tiles).
	Pre-create outside Terraform (recommend >= 100 GiB). Destroy will not delete it.
	EOT
	default = "ocid1.volume.oc1.eu-frankfurt-1.abtheljt4z55j2opff7brmm6ixswznzgvt7uiz4iy5wibnh3ya6fjupdatza"
}
