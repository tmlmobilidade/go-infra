# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-prd-tts-server"
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
	Static private IP for the TTS Server instance.
	Must be free within the public subnet — verify in OCI Console before applying.
	EOT
	default = "10.81.101.13"
}


# # #
# VM SHAPE

variable "base_image_ocid" {
	type = string
	description = "OCID of the Packer-built TTS Server image. Set after packer build."
	default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaksc5q2pz4i6n3jcivl7zd6xiba5uhqraqsrb6l4p7ppazrqt5q6q"
}

variable "vm_shape" {
	type = string
	description = "The shape of the VM."
	default = "VM.Standard.A1.Flex"
}

variable "vm_ocpus" {
	type = number
	description = "Number of OCPUs (match image ENV server_threads=4)."
	default = 2
}

variable "vm_memory_in_gbs" {
	type = number
	description = "Memory in GBs."
	default = 8
}

variable "boot_volume_size_in_gbs" {
	type = number
	description = "Boot volume size in GBs."
	default = 50
}


# # #
# STORAGE

# variable "block_volume_ocid" {
# 	type = string
# 	description = <<-EOT
# 	OCID of an existing block volume for TTS Server custom_files.
# 	Pre-create outside Terraform (recommend >= 100 GiB). Destroy will not delete it.
# 	EOT
# 	default = ""
# }


# # #
# SECRETS
variable "cloudflare_token_file" {
	type = string
	sensitive = true
	description = "Cloudflare API token used by Certbot."
}