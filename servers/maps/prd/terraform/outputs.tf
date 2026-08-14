# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP of the Maps instance."
	value = oci_core_instance.maps.private_ip
}

output "maps_url" {
	description = "Maps HTTP endpoint inside the VCN."
	value = "http://${oci_core_instance.maps.private_ip}:8002"
}

output "ssh_command" {
	description = "SSH via bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.maps.private_ip}"
}
