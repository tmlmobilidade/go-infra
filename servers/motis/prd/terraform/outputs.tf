# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP of the Motis instance."
	value = oci_core_instance.motis.private_ip
}

output "motis_url" {
	description = "Motis HTTP endpoint inside the VCN."
	value = "http://${oci_core_instance.motis.private_ip}:8002"
}

output "ssh_command" {
	description = "SSH via bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.motis.private_ip}"
}
