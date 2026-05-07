# # #
# OUTPUTS

output "instance_private_ips" {
	description = "Private IP addresses of the Postgres Instance."
	value = oci_core_instance.postgres[*].private_ip
}

output "ssh_commands" {
	description = "SSH commands to connect to each replica via a bastion/jump host."
	value = [for i in oci_core_instance.postgres : "ssh -J ubuntu@<bastion-ip> ubuntu@${i.private_ip}"]
}
