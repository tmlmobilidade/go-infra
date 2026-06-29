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
# Deploy Redis Replica VMs
# Each replica node is a separate instance
# with its own boot volume and attached data volume.

resource "oci_core_instance" "redis" {

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

		# cloud-init runs on first boot and configures Redis.
		user_data = base64encode(file("${path.module}/templates/cloud-init.yaml"))

	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
		"ReplicaIndex" = tostring(count.index + 1)
	}

}