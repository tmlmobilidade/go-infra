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
# Deploy ClickHouse Replica VMs
# Each replica node is a separate instance
# with its own boot volume and attached data volume.

resource "oci_core_instance" "clickhouse" {

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

	agent_config {
		is_monitoring_disabled = false
		is_management_disabled = false
		plugins_config {
			desired_state = "ENABLED"
			name = "Bastion"
		}
	}

	metadata = {

		ssh_authorized_keys = local.ssh_authorized_keys

		# cloud-init runs on first boot and configures ClickHouse Keeper + replication.
		# All node IPs are known at plan time (static assignment) so they are injected here.
		user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yaml", {
			node_index = count.index
			all_private_ips = var.private_ips
			clickhouse_admin_password = var.clickhouse_admin_password
			clickhouse_http_port = var.clickhouse_http_port
			clickhouse_tcp_port = var.clickhouse_tcp_port
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
# attached for ClickHouse data storage. These volumes
# are created separately to prevent accidental deletion
# when running Terraform commands.

resource "oci_core_volume_attachment" "clickhouse_data" {

	count = var.instance_count

	instance_id = oci_core_instance.clickhouse[count.index].id

	volume_id = var.block_volume_ocids[count.index]

	# Paravirtualized is easier to manage
	# in cloud-init than iSCSI
	attachment_type = "paravirtualized"

	is_pv_encryption_in_transit_enabled = false

}
