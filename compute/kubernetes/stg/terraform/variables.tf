# # #
# PROJECT VARIABLES

variable "display_name" {
	type = string
	description = "The name of the deployment. Used as the display name for resource names and tags."
	default = "iso-go-stg-kubernetes"
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

variable "vcn_ocid" {
	type = string
	description = "OCID of the existing VCN where the OKE cluster will be created."
	default = "ocid1.vcn.oc1.eu-frankfurt-1.amaaaaaaxpxrpiqabkt5rw4dfvcq7ft4qvelewczlgzyup54cdyetnz5wtta"
}

variable "subnet_ocid" {
	type = string
	description = "OCID of the existing subnet to attach resources to."
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaamognhazfxcnompsleq3oyfsufigrrw5753vp74hmheju7uuaxtba"
}


# # #
# CLUSTER CONFIGURATION

variable "kubernetes_version" {
	type = string
	description = "Kubernetes version for the cluster and node pool."
	default = "v1.35.0"
}


# # #
# NODE POOL

variable "pool_count" {
	type = number
	description = "Number of node pools to create."
	default = 1
}

variable "node_count" {
	type = number
	description = "Number of virtual nodes in the node pool."
	default = 3
}

variable "pod_shape" {
	type = string
	description = "The shape of the virtual node pods."
	default = "Pod.Standard.A1.Flex"
}
