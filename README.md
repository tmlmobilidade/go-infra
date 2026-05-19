# Infrastructure deployment

GO needs to run somewhere. We took great care to ensure it can run anywhere.
However, since our cloud is OCI, you will find here configuration files with this particular vendor idioms.

This repository contains the infrastructure deployment code for GO. It includes configuration files and scripts to deploy the necessary infrastructure for GO to run in production and staging environments. The infrastructure is deployed using Terraform, Packer, and Kubernetes, and it includes setup resources such as VMs, load balancers, databases, and more.

## What it does
- Builds and deploys infrastructure as code for production and staging
- Creates VM images with Packer
- Provisions resources with Terraform
- Configures Nginx as reverse proxy/load balancer
- Deploys containerized services on Kubernetes
- Manages database infrastructure for ClickHouse, MongoDB, and Redis

## Technologies used
 - Kubernetes
 - Packet
 - Nginx
 - Terraform
 - Flux CD
 - Databases: ClickHouse, MongoDB, PostgreSQL, Redis

### Nginx
 - Nginx is used as a reverse proxy and load balancer for our services. It helps to distribute incoming traffic across multiple backend servers.

### Packer
 - Packer is used to build our VMs images. It allows us to automate the process of creating and configuring VM images. It creates the base images that will be used to deploy our Kubernetes cluster and services.

### Terraform
 - Terraform is used to manage our infrastructure as code. 

### Kubernetes
 - Kubernetes is used to orchestrate and manage our containerized applications.

### Flux CD
 - Flux CD to monitors Git repository and synchronizes Kubernetes manifests into the Oracle Kubernetes Engine (OKE) cluster.


### Databases
#### MongoDB
 - MongoDB is used to store all information of the buses and their routes. In the case of Go, mongodb is used for authencathed API for authenticated users.
#### ClickHouse
 - ClickHouse is used to analyze the data collected from the vehicles positions and ticketing events in the future. It has a more simple schema and data model than MongoDB, and is optimized for analytical queries.
#### Redis
 - Redis is used as a caching layer to non authenticated users (general public), to improve the performance of our services. The user uses the public API that gets the data from redis. The data is updated in redis by a worker that gets the data from mongodb.
#### PostgreSQL
 - PostgreSQL is currently not in use. 

#
Inside every module, you will find a README.md file with more detailed information about the specific module, and instructions on how to use it.