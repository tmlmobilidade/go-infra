# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-stg-locationsdb"
}

variable "instance_count" {
	type = number
	description = "Number of locationsdb nodes to provision."
	default = 1
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
	OCID of the existing subnet to attach instances to.
	Networking is managed externally — this module creates no VCN, subnet,
	IGW, route table, security list, or NSG.
	Defaults to the shared pub-cmet subnet.
	EOT
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaamognhazfxcnompsleq3oyfsufigrrw5753vp74hmheju7uuaxtba"
}

variable "private_ip" {
	type = string
	description = <<-EOT
	Static private IP to assign to the node.
	Must be free within the existing subnet — verify in OCI Console > Networking before applying.
	EOT
	default = "10.91.101.191"
}


# # #
# VM SHAPE

variable "base_image_ocid" {
	type = string
	description = "OCID of the Packer-built image."
	default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaakwmhfe3vyrku5laoc7ljpo6rlgsbsyuush4a27kxzdzomleipz7a"
}

variable "vm_shape" {
	type = string
	description = "The shape of the VM."
	default = "VM.Standard.A1.Flex"
}

variable "vm_ocpus" {
	type = number
	description = "Number of OCPUs per replica VM."
	default = 4
}

variable "vm_memory_in_gbs" {
	type = number
	description = "Memory in GBs per replica VM."
	default = 24
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
	OCID for existing block volume to attach as data disk to the node.
	Each volume must be pre-created and match the count of replica nodes.
	EOT
	default = "ocid1.volume.oc1.eu-frankfurt-1.abtheljtntecbyklrbluze23god2zqigrhczhmo5d25dzcgfiabboxjiarwq"
}


# # #
# DATABASE CREDENTIALS

variable "locationsdb_password" {
	type = string
	sensitive = true
	description = <<-EOT
	Password for PostGIS user `osm` (DB `osm`).
	Written to /opt/app/secrets/.env on first boot via cloud-init.
	Generate e.g.: openssl rand -base64 32
	EOT
}