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

output "ssh_tunnel_command" {
	description = "SSH command to create a tunnel to the API endpoint of the cluster."
	value = "ssh -N -L 6443:${oci_containerengine_cluster.cluster.endpoints[0]}:6443 ubuntu@go-stg-jumpserver.tmlmobilidade.pt"
}
