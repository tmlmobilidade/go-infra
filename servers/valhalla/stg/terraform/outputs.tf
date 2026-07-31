# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP of the Valhalla instance."
	value = oci_core_instance.valhalla.private_ip
}

output "valhalla_url" {
	description = "Valhalla HTTP endpoint inside the VCN."
	value = "http://${oci_core_instance.valhalla.private_ip}:8002"
}

output "ssh_command" {
	description = "SSH via bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.valhalla.private_ip}"
}
