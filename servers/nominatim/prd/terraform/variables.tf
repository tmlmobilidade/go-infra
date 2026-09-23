# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-prd-nominatim"
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
	Current compartment is set to: go-prd
	EOT
	default = "ocid1.compartment.oc1..aaaaaaaade3kztlncv2ydpnbb5jl5hl6yqxyhkmezxhtj5dfjzsv27i3wf5a"
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
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaap4iuqtem64qsbejvu73u7ssm5n3eaa7ggds76zsokytka24q5pna"
}

variable "private_ip" {
	type = string
	description = <<-EOT
	Static private IP for the Nominatim instance.
	Must be free within the public subnet — verify in OCI Console before applying.
	EOT
	default = "10.81.101.9"
}


# # #
# VM SHAPE

variable "base_image_ocid" {
	type = string
	description = "OCID of the Packer-built Nominatim image. Set after packer build."
	default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa6pxmrd2slbk5zefiuv5llbjcn7i3flme5je5y3jk7cwao6xpkpga"
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
	OCID of an existing block volume for Nominatim data.
	EOT
	default = "ocid1.volume.oc1.eu-frankfurt-1.abtheljtf7z2c6ajcf45av7y2rywkfx4dlbmcthbkpjil3xfetj6lis6x7mq"
}


# # #
# SECRETS
variable "cloudflare_token_file" {
	type = string
	sensitive = true
	description = "Cloudflare API token used by Certbot."
}