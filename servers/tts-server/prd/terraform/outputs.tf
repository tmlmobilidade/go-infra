# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP of the TTS Server instance."
	value = oci_core_instance.tts-server.private_ip
}

output "tts-server_url" {
	description = "TTS Server HTTP endpoint inside the VCN."
	value = "http://${oci_core_instance.tts-server.private_ip}:8002"
}

output "ssh_command" {
	description = "SSH via bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.tts-server.private_ip}"
}
