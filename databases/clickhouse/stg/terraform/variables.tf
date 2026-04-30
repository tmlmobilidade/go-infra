# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-stg-clickhouse"
}

variable "instance_count" {
	type = number
	description = "Number of ClickHouse replica nodes to provision."
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
	EOT
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaamognhazfxcnompsleq3oyfsufigrrw5753vp74hmheju7uuaxtba"
}

variable "private_ips" {
	type = list(string)
	description = <<-EOT
	List of 3 static private IP addresses to assign to the replica nodes (one per node).
	Must be free within the existing subnet — verify in OCI Console > Networking before applying.
	EOT
	default = [
		"10.91.101.141",
		"10.91.101.142",
		"10.91.101.143"
	]
}


# # #
# VM SHAPE

variable "base_image_ocid" {
	type = string
	description = "OCID of the Packer-built image."
	default = ""
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
		"ocid1.volume.oc1.eu-frankfurt-1.abtheljtp246n77d2nuk67bcszjlzdcpmjf6l6jbalprwijd2awiaemmgx6q",
		"ocid1.volume.oc1.eu-frankfurt-1.abtheljt4f7yd4cozat2ukam7azu7ovq4unbgavehjfs6r67cebdhfvqgayq",
		"ocid1.volume.oc1.eu-frankfurt-1.abtheljt4gqqvj3hyrob6p56h6dppjr2tb4l6sondp6lbw42iogunkxsoi3a"
	]
}


# # #
# CLICKHOUSE

variable "clickhouse_http_port" {
	type = number
	description = "ClickHouse HTTP interface port."
	default = 8123
}

variable "clickhouse_tcp_port" {
	type = number
	description = "ClickHouse native TCP port."
	default = 9000
}

variable "clickhouse_admin_password" {
	type = string
	sensitive = true
	description = "Password for the ClickHouse default admin user."
}
