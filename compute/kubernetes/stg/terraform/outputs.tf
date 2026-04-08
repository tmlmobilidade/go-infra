# # #
# OUTPUTS

output "cluster_id" {
	description = "OCID of the OKE cluster."
	value = oci_containerengine_cluster.k8s.id
}

output "cluster_kubernetes_version" {
	description = "Kubernetes version running on the cluster."
	value = oci_containerengine_cluster.k8s.kubernetes_version
}

output "cluster_endpoints" {
	description = "Kubernetes API server endpoints."
	value = oci_containerengine_cluster.k8s.endpoints
}

output "node_pool_id" {
	description = "OCID of the worker node pool."
	value = oci_containerengine_node_pool.workers.id
}

output "node_image_id" {
	description = "OCID of the node image used by the worker node pool."
	value = local.node_image_ocid
}

output "kubeconfig_command" {
	description = "OCI CLI command to generate the kubeconfig for this cluster."
	value = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.k8s.id} --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
}
