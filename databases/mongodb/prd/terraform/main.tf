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
# Values come from `{environment}.tfvars`

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
# COMPUTE
# Deploy MongoDB Replica VMs
# Each replica node is a separate instance
# with its own boot volume and attached data volume.

resource "oci_core_instance" "mongodb" {

	display_name = "${var.display_name}-${count.index + 1}"

	count = var.instance_count

	compartment_id = var.compartment_ocid
	availability_domain = var.availability_domain

	shape = var.vm_shape

	shape_config {
		ocpus = var.vm_ocpus
		memory_in_gbs = var.vm_memory_in_gbs
	}

	source_details {
		source_type = "image"
		source_id = var.base_image_ocid
		boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
	}

	create_vnic_details {
		display_name = "${var.display_name}-${count.index + 1}-vnic"
		subnet_id = var.subnet_ocid
		private_ip = var.private_ips[count.index]
		assign_public_ip = false
	}

	metadata = {

		ssh_authorized_keys = local.ssh_authorized_keys

		# cloud-init runs on first boot and configures MongoDB replica set.
		# All node IPs are known at plan time so they are injected into the template.
		# Only node 0 (primary) runs rs.initiate() after the container starts.
		user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml", {
			node_index = count.index
			all_private_ips = var.private_ips
			mongodb_root_username = var.mongodb_root_username
			mongodb_root_password = var.mongodb_root_password
			mongodb_keyfile = var.mongodb_keyfile
			mongodb_port = var.mongodb_port
		}))

	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
		"ReplicaIndex" = tostring(count.index + 1)
	}

}


# # #
# BLOCK VOLUMES ATTACHMENT
# Each replica node has a dedicated data volume
# attached for MongoDB data storage. These volumes
# are created separately to prevent accidental deletion
# when running Terraform commands.

resource "oci_core_volume_attachment" "mongodb_data" {

	count = var.instance_count

	instance_id = oci_core_instance.mongodb[count.index].id

	volume_id = var.block_volume_ocids[count.index]

	# Paravirtualized is easier to manage
	# in cloud-init than iSCSI
	attachment_type = "paravirtualized"

	is_pv_encryption_in_transit_enabled = false

}
