# # #
# OUTPUTS

output "instance_private_ip" {
	description = "Private IP of the LocationsDB instance."
	value = oci_core_instance.locationsdb.private_ip
}

output "ssh_command" {
	description = "SSH via bastion/jump host."
	value = "ssh -J ubuntu@<bastion-ip> ubuntu@${oci_core_instance.locationsdb.private_ip}"
}

output "import_log" {
	description = "Check OSM import progress on the host."
	value = "tail -f /opt/app/import.log"
}
