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
# COMPUTE
# Deploy a Gateway VM.

resource "oci_core_instance" "gateway" {

	display_name = var.display_name

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
		display_name = "${var.display_name}-vnic"
		subnet_id = var.subnet_ocid
		private_ip = var.private_ip
		assign_public_ip = true
	}

	metadata = {
		ssh_authorized_keys = local.ssh_authorized_keys
		# cloud-init runs on first boot and configures Gateway.
		# All node IPs are known at plan time (static assignment) so they are injected here.
		user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml"))
	}

	freeform_tags = {
		"TerraformModule" = var.display_name
		"ManagedBy" = "terraform"
	}

}