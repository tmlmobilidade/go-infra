# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-prd-godb"
}

variable "instance_count" {
	type = number
	description = "Number of MongoDB replica nodes to provision."
	default = 3
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
	Current compartment is set to: cmet
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
	OCID of the existing subnet to attach instances to.
	Networking is managed externally — this module creates no VCN, subnet,
	IGW, route table, security list, or NSG.
	Defaults to the shared pub-cmet subnet.
	EOT
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaaqwztdskuufaajsp2wz3htvywxlywkwcj63zof52hr7gywnnssbxa"
}

variable "private_ips" {
	type = list(string)
	description = <<-EOT
	List of 3 static private IP addresses to assign to the replica nodes (one per node).
	Must be free within the existing subnet — verify in OCI Console > Networking before applying.
	EOT
	default = [
		"10.81.101.211",
		"10.81.101.212",
		"10.81.101.213"
	]
}


# # #
# VM SHAPE

variable "base_image_ocid" {
	type = string
	description = "OCID of the Packer-built image."
	default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaaeqy4at4g7b7hydxgkzj2dnfkryfr23hwkchgrv6cowaffrl47lea"
}

variable "vm_shape" {
	type = string
	description = "The shape of the VM."
	default = "VM.Standard.A1.Flex"
}

variable "vm_ocpus" {
	type = number
	description = "Number of OCPUs per replica VM."
	default = 2
}

variable "vm_memory_in_gbs" {
	type = number
	description = "Memory in GBs per replica VM."
	default = 12
}

variable "boot_volume_size_in_gbs" {
	type = number
	description = "Boot volume size in GBs."
	default = 50
}


# # #
# STORAGE

variable "block_volume_ocids" {
	type = list(string)
	description = <<-EOT
	List of OCIDs for existing block volumes to attach as data disks to the replica nodes.
	Each volume must be pre-created and match the count of replica nodes.
	EOT
	default = [
		"ocid1.volume.oc1.eu-frankfurt-1.abtheljtf5ds2x77k2pov4xexa6awq72hdefdsuzcle3f76i4k6r4bhlsx4a",
		"ocid1.volume.oc1.eu-frankfurt-1.abtheljthmgs4iu4f2yke5ohcxw2g7qygl27khiqkaraswue5tqpglnavkgq",
		"ocid1.volume.oc1.eu-frankfurt-1.abtheljtbmzqxad2ocyoz55m4ekthnlph2ix3hnlayic7gnnscdc5sqxhisa",
	]
}


# # #
# MONGODB

variable "mongodb_port" {
	type = number
	description = "MongoDB listening port."
	default = 27017
}

variable "mongodb_root_username" {
	type = string
	description = "MongoDB root username."
	default = "admin"
}

variable "mongodb_root_password" {
	type = string
	sensitive = true
	description = "MongoDB root password."
}

variable "mongodb_keyfile" {
	type = string
	sensitive = true
	description = <<-EOT
	Shared keyfile content for MongoDB replica set internal authentication.
	All nodes must use the same keyfile. Generate once with: `openssl rand -base64 756`
	Then paste the output (including newlines) as the value of this variable.
	EOT
}
