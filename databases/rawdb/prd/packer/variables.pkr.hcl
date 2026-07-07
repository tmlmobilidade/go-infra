# # #
# PACKER VARIABLES
# Define variables for Packer templates.

variable "display_name" {
	type = string
	description = "The name of the project. This will be used as a prefix for resource names and tags."
	default = "iso-go-prd-mongodb"
}

variable "compartment_ocid" {
	type = string
	description = <<-EOT
	The OCID of the compartment where resources will be created in.
	Current compartment is set to: go-prd
	EOT
	default = "ocid1.compartment.oc1..aaaaaaaade3kztlncv2ydpnbb5jl5hl6yqxyhkmezxhtj5dfjzsv27i3wf5a"
}

variable "subnet_ocid" {
	type = string
	description = <<-EOT
	The OCID of the subnet where the VM will be created.
	For Packer builds, this subnet must have public access
	to the internet, so it should be a public subnet.
	EOT
	default = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaap4iuqtem64qsbejvu73u7ssm5n3eaa7ggds76zsokytka24q5pna"
}

variable "availability_domain" {
	type = string
	description = <<-EOT
	The availability domain where resources will be created.
	This should be the full ID string, e.g., 'LUDo:EU-FRANKFURT-1-AD-1'.
	This can only be found via the OCI CLI or by inspecting the API response
	for VM instance details on the web console.
	EOT
	default = "LUDo:EU-FRANKFURT-1-AD-1"
}

variable "vm_shape" {
	type = string
	description = <<-EOT
	The shape of the VM to be created, i.e., the compute resources allocated to the VM machine
	that will be used to build the final image. For building lightweight images, a small shape is sufficient.
	EOT
	default = "VM.Standard.A1.Flex"
}

variable "vm_ocpus" {
	type = number
	description = <<-EOT
	The number of OCPUs to allocate to the VM used for building the image.
	It is not recommended to use less than 2 OCPUs because the machine might hang due to insufficient resources.
	The building process can be CPU intensive and is very short lived (the machine is destroyed afterwards),
	so having more resources is beneficial and not expensive.
	EOT
	default = 2
}

variable "vm_memory_in_gbs" {
	type = number
	description = <<-EOT
	The amount of memory in GBs to allocate to the VM used for building the image.
	It is not recommended to use less than 2 GBs because the machine might hang due to insufficient resources.
	The building process can be memory intensive and is very short lived (the machine is destroyed afterwards),
	so having more resources is beneficial and not expensive.
	EOT
	default = 4
}

variable "base_image_ocid" {
	type = string
	description = <<-EOT
	The OCID of the base image to use for the VM.
	It is recommended to use a *minimal* Ubuntu image to reduce the final image size.
	This should be regularly updated to the latest available minimal Ubuntu image.
	Current image is set to: Canonical-Ubuntu-24.04-Minimal-aarch64-2026.02.28-0"
	EOT
	default = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaav7j5fmkuvwreezyn7pkyyzgexm4uaobnceclctrmkj2urjvo6e5a"
}