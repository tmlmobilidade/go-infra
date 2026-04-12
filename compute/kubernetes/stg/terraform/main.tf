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
# LOCALS
# Local values are computed at plan time
# and can be used throughout the module.

locals {
	ssh_authorized_keys = file(var.ssh_authorized_keys_path)
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
		cni_type = "FLANNEL_OVERLAY"
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

resource "oci_containerengine_node_pool" "node_pool" {

	count = var.pool_count

	name = "${var.display_name}-pool-${count.index + 1}"

	cluster_id = oci_containerengine_cluster.cluster.id
	compartment_id = var.compartment_ocid

	node_shape = var.node_shape

	ssh_public_key = local.ssh_authorized_keys

	node_shape_config {
		ocpus = var.node_ocpus
		memory_in_gbs = var.node_memory_in_gbs
	}

	node_config_details {

		size = var.node_count

		placement_configs {
			availability_domain = var.availability_domain
			subnet_id = var.subnet_ocid
		}

	}

	node_source_details {
		source_type = "IMAGE"
		image_id = var.node_image_ocid
		boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
	}

	node_pool_cycling_details {
		maximum_surge = 1
	}

	node_metadata = {
		# Extend the root filesystem to use the full boot volume size.
		# OCI provisions the boot volume at the requested size but Oracle Linux
		# images ship with a small root partition (~36 GB). oci-growfs extends
		# the last partition and resizes the filesystem to fill the disk.
		user_data = base64encode(<<-EOF
			#cloud-config
			runcmd:
			  - /usr/libexec/oci-growfs -y
			EOF
		)
	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
	}

}
