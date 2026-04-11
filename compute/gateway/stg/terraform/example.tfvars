# # #
# OCI AUTHENTICATION
# Copy this file to terraform.tfvars and fill in the values.
# Never commit terraform.tfvars to source control.

tenancy_ocid = ""
user_ocid = ""
fingerprint = ""
private_key_path = "~/.oci/oci_api_key.pem"

# # #
# SSH ACCESS
# This is the authorized keys files that will be added
# to the `~/.ssh/authorized_keys` of each instance,
# allowing you to SSH into them using the corresponding private key.

ssh_authorized_keys_path = "/path/to/authorized_keys"

# # #
# CLOUDFLARE API TOKEN
# This is the API token used by Certbot
# to manage DNS records for domain validation.
# Create a token with the following permissions:
# - Zone:DNS:Edit

cloudflare_token_file = <<-EOT
# Cloudflare API token used by Certbot
dns_cloudflare_api_token = 1234567890
EOT
