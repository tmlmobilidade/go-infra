# # #
# TERRAFORM SETTINGS

terraform {
	required_providers {
		oci = {
			source = "oracle/oci"
			version = "~> 7"
		}
	}
}


# # #
# OCI AUTHENTICATION
# Variables defined in `variables.tf`
# Values come from `terraform.tfvars`

provider "oci" {
	tenancy_ocid = var.tenancy_ocid
	user_ocid = var.user_ocid
	fingerprint = var.fingerprint
	private_key_path = var.private_key_path
	region = var.region
}


# # #
# OKE CLUSTER
# Deploy an OCI Kubernetes Engine (OKE) managed cluster.
# This module creates zero networking resources. The cluster
# attaches to the existing VCN and subnets provided via variables.

resource "oci_containerengine_cluster" "cluster" {

	name = var.display_name

	compartment_id = var.compartment_ocid
	vcn_id = var.vcn_ocid
	kubernetes_version = var.kubernetes_version
	type = "ENHANCED_CLUSTER"

	endpoint_config {
		is_public_ip_enabled = false
		subnet_id = var.subnet_ocid
	}

	cluster_pod_network_options {
		cni_type = "OCI_VCN_IP_NATIVE"
	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
	}

}


# # #
# VIRTUAL NODE POOL
# Deploy a pool of virtual (serverless) nodes for the OKE cluster.
# No node shape, SSH keys, or custom images are required.

resource "oci_containerengine_virtual_node_pool" "virtual_node_pool" {

	count = var.pool_count

	display_name = "${var.display_name}-pool-${count.index + 1}"

	cluster_id = oci_containerengine_cluster.cluster.id
	compartment_id = var.compartment_ocid

	size = var.node_count

	placement_configurations {
		availability_domain = var.availability_domain
		subnet_id = var.subnet_ocid
		fault_domain = ["FAULT-DOMAIN-1"]
	}

	pod_configuration {
		shape = var.pod_shape
		subnet_id = var.subnet_ocid
	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
	}

}
