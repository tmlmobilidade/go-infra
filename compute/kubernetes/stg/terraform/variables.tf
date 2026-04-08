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

variable "ssh_authorized_keys_path" {
	type = string
	description = "The file path to the SSH authorized keys to allow node access."
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
	description = "The availability domain where worker nodes will be placed (e.g. 'LUDo:EU-FRANKFURT-1-AD-1')."
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
	description = <<-EOT
	OCID of the existing VCN where the OKE cluster will be created.
	Networking is managed externally — this module creates no VCN, subnet,
	IGW, route table, security list, or NSG.
	EOT
}

variable "api_endpoint_subnet_ocid" {
	type = string
	description = "OCID of the existing subnet for the Kubernetes API endpoint."
}

variable "worker_node_subnet_ocid" {
	type = string
	description = "OCID of the existing subnet where worker nodes will be placed."
}

variable "service_lb_subnet_ocid" {
	type = string
	description = "OCID of the existing subnet for Kubernetes LoadBalancer services."
}


# # #
# CLUSTER CONFIGURATION

variable "kubernetes_version" {
	type = string
	description = "Kubernetes version for the cluster and node pool. Leave empty to use the latest available version."
	default = ""
}

variable "cluster_type" {
	type = string
	description = "OKE cluster type. Use 'BASIC_CLUSTER' (free) or 'ENHANCED_CLUSTER' (paid, adds features like virtual nodes and workload identity)."
	default = "BASIC_CLUSTER"
}

variable "cluster_endpoint_is_public" {
	type = bool
	description = "Whether the Kubernetes API endpoint should have a public IP address."
	default = true
}

variable "pods_cidr" {
	type = string
	description = "CIDR block for pod IPs (Flannel overlay network)."
	default = "10.244.0.0/16"
}

variable "services_cidr" {
	type = string
	description = "CIDR block for Kubernetes service ClusterIPs."
	default = "10.96.0.0/16"
}


# # #
# NODE POOL

variable "node_count" {
	type = number
	description = "Number of worker nodes in the node pool."
	default = 3
}

variable "node_shape" {
	type = string
	description = "The shape of the worker node VMs."
	default = "VM.Standard.E4.Flex"
}

variable "node_ocpus" {
	type = number
	description = "Number of OCPUs per worker node."
	default = 2
}

variable "node_memory_in_gbs" {
	type = number
	description = "Memory in GBs per worker node."
	default = 16
}

variable "boot_volume_size_in_gbs" {
	type = number
	description = "Boot volume size in GBs per worker node."
	default = 50
}

variable "node_image_ocid" {
	type = string
	description = "OCID of the node image. Leave empty to auto-discover the latest OKE-optimized Oracle Linux image for the selected shape."
	default = ""
}
