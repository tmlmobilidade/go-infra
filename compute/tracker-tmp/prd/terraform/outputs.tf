# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP address of the Tracker instance."
	value = oci_core_instance.tracker.private_ip
}


output "ssh_commands" {
	description = "SSH commands to connect to the Tracker instance via a bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.tracker.private_ip}"
}