# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP of the Nominatim instance."
	value = oci_core_instance.nominatim.private_ip
}

output "nominatim_url" {
	description = "Nominatim HTTP endpoint inside the VCN."
	value = "http://${oci_core_instance.nominatim.private_ip}:8002"
}

output "ssh_command" {
	description = "SSH via bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.nominatim.private_ip}"
}
