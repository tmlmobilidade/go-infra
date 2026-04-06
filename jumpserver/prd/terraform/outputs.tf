# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP address of the JumpServer instance."
	value = oci_core_instance.jumpserver.private_ip
}

output "ssh_command" {
	description = "SSH command to connect to the JumpServer instance."
	value = "ssh -i <private-key-path> ubuntu@${oci_core_instance.jumpserver.public_ip}"
}
