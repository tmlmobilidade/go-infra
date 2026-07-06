# # #
# OUTPUTS

output "instance_private_ips" {
	description = "Private IP addresses of the 3 MongoDB replica instances."
	value = oci_core_instance.mongodb[*].private_ip
}

output "mongodb_dsns" {
	description = "MongoDB connection strings for each node (accessible from within the VCN)."
	value = [for i in oci_core_instance.mongodb : "mongodb://${var.mongodb_root_username}:<password>@${i.private_ip}:${var.mongodb_port}/?authSource=admin"]
}

output "replica_set_dsn" {
	description = "MongoDB Replica Set connection string (connect via any node; driver discovers primary)."
	value = "mongodb://${var.mongodb_root_username}:<password>@${join(",", [for i in oci_core_instance.mongodb : "${i.private_ip}:${var.mongodb_port}"])}/?replicaSet=rs0&authSource=admin"
}

output "ssh_commands" {
	description = "SSH commands to connect to each replica via a bastion/jump host."
	value = [for i in oci_core_instance.mongodb : "ssh -J ubuntu@<bastion-ip> ubuntu@${i.private_ip}"]
}
