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
# MONGODB
# Generate a random keyfile for MongoDB replica set authentication with
# `openssl rand -base64 756` Paste the full multi-line output below
# (between the EOT markers in tfvars). For the password, generate a
# 64 character password and paste it below.

mongodb_root_username = "admin"
mongodb_root_password = ""
mongodb_keyfile = <<-EOT
PASTE GENERATED KEYFILE HERE
EOT

# # #
# NETWORKING
# Static private IPs for the 3 replica nodes.
# Verify these IPs are free in your OCI subnet before applying.
# Go to: OCI > Networking > Virtual Cloud Networks > [your subnet] > IP Addresses
# e.g. ["10.0.1.20", "10.0.1.21", "10.0.1.22"]

subnet_ocid = ""

# # #
# BLOCK STORAGE
# Create block volumes separately paste each OCID below.
# They must be in the same availability domain as your compute instances.
# e.g. ["ocid1...", "ocid2...", "ocid3..."]

block_volume_ocids = ["", "", ""]