# # #
# OUTPUTS

output "cluster_id" {
	description = "OCID of the OKE cluster."
	value = oci_containerengine_cluster.cluster.id
}

output "cluster_endpoints" {
	description = "Kubernetes API server endpoints."
	value = oci_containerengine_cluster.cluster.endpoints
}

output "kubeconfig_command" {
	description = "OCI CLI command to generate the kubeconfig for this cluster."
	value = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.cluster.id} --region ${var.region}"
}
