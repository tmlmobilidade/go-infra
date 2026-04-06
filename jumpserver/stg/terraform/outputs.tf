# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP address of the JumpServer instance."
	value = oci_core_instance.jumpserver.private_ip
}

output "instance_public_ip" {
	description = "Public IP address of the JumpServer instance."
	value = oci_core_instance.jumpserver.public_ip
}

output "ssh_command" {
	description = "SSH command to connect to the JumpServer instance."
	value = "ssh ubuntu@${oci_core_instance.jumpserver.public_ip}"
}
