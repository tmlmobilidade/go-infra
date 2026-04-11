# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-prd-gateway"
}


# # #
# OCI AUTHENTICATION

variable "tenancy_ocid" {
	type = string
	description = "The OCID of the Oracle Cloud Infrastructure tenancy."
}

variable "user_ocid" {
	type = string
	description = "The OCID of the OCI user used for API authentication."
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
	description = "OCID of the existing subnet to attach instances to."
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaap4iuqtem64qsbejvu73u7ssm5n3eaa7ggds76zsokytka24q5pna"
}

variable "private_ip" {
	type = string
	description = <<-EOT
	Static private IP address to assign to the instance.
	Must be free within the existing subnet — verify in OCI Console > Networking before applying.
	EOT
	default = "10.81.101.2"
}


# # #
# VM SHAPE

variable "base_image_ocid" {
	type = string
	description = <<-EOT
	The OCID of the base image to use for the VM.
	It is recommended to use a *minimal* Ubuntu image to reduce the final image size.
	This should be regularly updated to the latest available minimal Ubuntu image.
	EOT
	default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaacdnlkdr7yezgqqk2osp4zd6mwfvlfvrnnodoectekyvgnlf57aeq"
}

variable "vm_shape" {
	type = string
	description = "The shape of the VM."
	default = "VM.Standard.A1.Flex"
}

variable "vm_ocpus" {
	type = number
	description = "Number of OCPUs per VM."
	default = 2
}

variable "vm_memory_in_gbs" {
	type = number
	description = "Memory in GBs per VM."
	default = 2
}

variable "boot_volume_size_in_gbs" {
	type = number
	description = "Boot volume size in GBs."
	default = 50
}