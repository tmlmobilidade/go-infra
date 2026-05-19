# Infrastructure deployment

GO needs to run somewhere. We took great care to ensure it can run anywhere.
However, since our cloud is OCI, you will find here configuration files with this particular vendor idioms.

ssh -J ubuntu@go-prd-jumpserver.tmlmobilidade.pt ubuntu@10.81.101.178

This module includes a Terraform configuration that deploys the infrastructure for GO in production and staging environments. It uses Packer to build VM images, Terraform to provision resources, Nginx as a reverse proxy/load balancer, Kubernetes to deploy containerized services, and manages database infrastructure for ClickHouse, MongoDB, and Redis.

### Nginx
 - Nginx is used as a reverse proxy and load balancer for our services. It helps to distribute incoming traffic across multiple backend servers.
 - It uses a dockerfile to build the image and a configuration file to set up the reverse proxy and load balancing rules.
 - The Nginx configuration is designed to route traffic to the appropriate backend services based on the incoming request.


### Packer
 - Packer is used to build our VMs images. It allows us to automate the process of creating and configuring VM images. It creates the base images that will be used to deploy our Kubernetes cluster and services.
 - It uses a compose file to define the services and configuration for building the images. The images are built with the necessary software and configurations to run our services.
 - Compose file includes the services of watchtower, certbot, nginx and docs.
 - Uses watchtower to automatically rebuild and redeploy the images when changes are made to the configuration.
 - Certbot is used to manage SSL certificates for our services.
 - Usage instructions can be found in the `prd (or stg)/packer/README.md` file.

### Terraform
- Terraform is used to manage our infrastructure as code that will be deployed in OCI. 
- It uses configuration files to define the resources and their dependencies.
- Usage instructions can be found in the `prd (or stg)/terraform/README.md` file.
