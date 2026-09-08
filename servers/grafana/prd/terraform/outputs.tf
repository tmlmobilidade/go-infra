# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP of the Grafana instance."
	value = oci_core_instance.grafana.private_ip
}

output "grafana_url" {
	description = "Grafana HTTP endpoint inside the VCN."
	value = "http://${oci_core_instance.grafana.private_ip}:8002"
}

output "ssh_command" {
	description = "SSH via bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.grafana.private_ip}"
}
