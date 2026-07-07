# -----------------------------------------------------------------------
# clickhouse-oci.pkr.hcl
#
# Builds a custom OCI image for ClickHouse Replica nodes with Docker and
# OS tuning pre-installed. The resulting image is used by Terraform in
# place of the raw Ubuntu base image, speeding up instance boot.
#
# USAGE:
#   packer init .
#   cp ../terraform/terraform.tfvars ../terraform/terraform.pkrvars.hcl   # Packer requires .hcl extension
#   packer build -var-file=../terraform/terraform.pkrvars.hcl -warn-on-undeclared-var .
# -----------------------------------------------------------------------


# # #
# PLUGIN
# Setup required OCI Packer plugin.

packer {
	required_plugins {
		oracle = {
			source = "github.com/hashicorp/oracle"
			version = "~> 1"
		}
	}
}


# # #
# SOURCE
# Configure the VM that will be used
# to create the final output image.

source "oracle-oci" "clickhouse_base" {

	# In HashiCorp Packer, the isotime function expects
	# a Go time format layout. Go uses the reference date:
	# Mon Jan 2 15:04:05 MST 2006
	image_name = "${var.display_name}-{{isotime \"2006-01-02\"}}"

	instance_name = "${var.display_name}-packer"

	# Placement
	subnet_ocid = var.subnet_ocid
	compartment_ocid = var.compartment_ocid
	availability_domain = var.availability_domain
	ssh_username = "ubuntu"

	base_image_ocid = var.base_image_ocid

	shape = var.vm_shape

	shape_config {
		ocpus = var.vm_ocpus
		memory_in_gbs = var.vm_memory_in_gbs
	}

	create_vnic_details {
		assign_public_ip = "true"
	}

	tags = {
		"PackerBuilt" = "true"
		"ManagedBy" = "packer"
		"ImageType" = var.display_name
	}

}


# # #
# BUILD
# Define the steps to customize the image.

build {

	sources = ["source.oracle-oci.clickhouse_base"]

	# 1.
	# OS performance tuning + install prerequisite packages

	provisioner "shell" {
		script = "${path.root}/setup/os-tuning.sh"
		execute_command = "sudo bash '{{.Path}}'"
	}

	# 2.
	# Install netutils packages for network troubleshooting.

	provisioner "shell" {
		script = "${path.root}/setup/install-netutils.sh"
		execute_command = "sudo bash '{{.Path}}'"
	}

	# 3.
	# Install Docker Engine

	provisioner "shell" {
		script = "${path.root}/setup/install-docker.sh"
		execute_command = "sudo bash '{{.Path}}'"
	}

	# 4.
	# Copy setup scripts that cloud-init can call at boot time.
	# Since Packer file provisioners do not support setting executable
	# permissions on the files, an additional shell provisioner is used
	# to move the files to the final location and set the correct permissions.

	provisioner "shell" {
		inline = [
			"sudo mkdir -p /opt/app",
			"sudo chown ubuntu:ubuntu /opt/app"
		]
	}

	# The attach-volume.sh script is responsible
	# for attaching and mounting the block volume.

	provisioner "file" {
		source = "${path.root}/init/attach-volume.sh"
		destination = "/opt/app/attach-volume.sh"
	}

	provisioner "shell" {
		inline = [
			"sudo chmod +x /opt/app/attach-volume.sh"
		]
	}

	# The firewall.sh script is responsible for
	# configuring the firewall to allow ClickHouse traffic.

	provisioner "file" {
		source = "${path.root}/init/firewall.sh"
		destination = "/opt/app/firewall.sh"
	}

	provisioner "shell" {
		inline = [
			"sudo chmod +x /opt/app/firewall.sh"
		]
	}

	# The setup-clickhouse.sh script is responsible for
	# setting up the ClickHouse data directories and permissions.

	provisioner "file" {
		source = "${path.root}/init/setup-clickhouse.sh"
		destination = "/opt/app/setup-clickhouse.sh"
	}

	provisioner "shell" {
		inline = [
			"sudo chmod +x /opt/app/setup-clickhouse.sh"
		]
	}

	# The compose.yaml file holds the configuration
	# that defines the ClickHouse container and its settings.

	provisioner "file" {
		source = "${path.root}/init/compose.yaml"
		destination = "/opt/app/compose.yaml"
	}

	# 5.
	# Clean up apt cache to reduce image size

	provisioner "shell" {
		inline = [
			"sudo apt-get clean",
			"sudo cloud-init clean --logs",
		]
	}

	# 6.
	# Generate a manifest file with the image OCID
	# for later use in Terraform pipelines.

	post-processor "manifest" {
		output = "${path.root}/packer-manifest.json"
		strip_path = true
	}

}
