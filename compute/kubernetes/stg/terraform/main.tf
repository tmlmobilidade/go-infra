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
# DATA SOURCES
# Discover available Kubernetes versions and
# OKE-optimized node images for the selected shape.

data "oci_containerengine_cluster_option" "k8s" {
	cluster_option_id = "all"
	compartment_id = var.compartment_ocid
}

data "oci_core_images" "oke_node" {
	compartment_id = var.compartment_ocid
	shape = var.node_shape
	state = "AVAILABLE"
	sort_by = "TIMECREATED"
	sort_order = "DESC"

	filter {
		name = "display_name"
		regex = true
		values = ["^Oracle-Linux-[0-9].*-OKE-.*$"]
	}
}


# # #
# LOCALS
# Local values are computed at plan time
# and can be used throughout the module.

locals {
	ssh_authorized_keys = file(var.ssh_authorized_keys_path)
	available_k8s_versions = sort(data.oci_containerengine_cluster_option.k8s.kubernetes_versions)
	kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : local.available_k8s_versions[length(local.available_k8s_versions) - 1]
	node_image_ocid = var.node_image_ocid != "" ? var.node_image_ocid : data.oci_core_images.oke_node.images[0].id
}


# # #
# OKE CLUSTER
# Deploy an OCI Kubernetes Engine (OKE) managed cluster.
# This module creates zero networking resources. The cluster
# attaches to the existing VCN and subnets provided via variables.

resource "oci_containerengine_cluster" "k8s" {

	name = var.display_name

	compartment_id = var.compartment_ocid
	vcn_id = var.vcn_ocid
	kubernetes_version = local.kubernetes_version
	type = var.cluster_type

	endpoint_config {
		is_public_ip_enabled = var.cluster_endpoint_is_public
		subnet_id = var.api_endpoint_subnet_ocid
	}

	cluster_pod_network_options {
		cni_type = "FLANNEL_OVERLAY"
	}

	options {
		service_lb_subnet_ids = [var.service_lb_subnet_ocid]

		kubernetes_network_config {
			pods_cidr = var.pods_cidr
			services_cidr = var.services_cidr
		}
	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
	}

}


# # #
# NODE POOL
# Deploy a pool of worker nodes for the OKE cluster.
# Uses OKE-optimized Oracle Linux images discovered
# automatically, or a custom image if specified.

resource "oci_containerengine_node_pool" "workers" {

	name = "${var.display_name}-workers"

	cluster_id = oci_containerengine_cluster.k8s.id
	compartment_id = var.compartment_ocid
	kubernetes_version = local.kubernetes_version

	node_shape = var.node_shape

	node_shape_config {
		ocpus = var.node_ocpus
		memory_in_gbs = var.node_memory_in_gbs
	}

	node_config_details {

		size = var.node_count

		placement_configs {
			availability_domain = var.availability_domain
			subnet_id = var.worker_node_subnet_ocid
		}
	}

	node_source_details {
		source_type = "IMAGE"
		image_id = local.node_image_ocid
		boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
	}

	ssh_public_key = local.ssh_authorized_keys

	initial_node_labels {
		key = "environment"
		value = "staging"
	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
	}

}
