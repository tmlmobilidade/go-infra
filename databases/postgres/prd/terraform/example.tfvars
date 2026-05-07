# # #
# ENVIRONMENT

environment = "stg" | "prd"

# # #
# OCI AUTHENTICATION
# Copy this file to terraform.tfvars and fill in the values.
# Never commit terraform.tfvars to source control.

tenancy_ocid = ""
user_ocid = ""
fingerprint = ""
private_key_path = "~/.oci/oci_api_key.pem"

# # #
# PLACEMENT

compartment_ocid = ""

# # #
# SSH ACCESS
# This is the authorized keys files that will be added
# to the `~/.ssh/authorized_keys` of each instance,
# allowing you to SSH into them using the corresponding private key.

ssh_authorized_keys_path = "/path/to/authorized_keys"

# # #
# NETWORKING
# Static private IPs for the 3 replica nodes.
# Verify these IPs are free in your OCI subnet before applying.
# Go to: OCI > Networking > Virtual Cloud Networks > [your subnet] > IP Addresses
# e.g. ["10.0.1.20", "10.0.1.21", "10.0.1.22"]

subnet_ocid = ""

# # #
# CLICKHOUSE
# Generate 64 character random password for ClickHouse admin user.

postgres_admin_password = ""