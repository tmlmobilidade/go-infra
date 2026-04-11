#!/bin/bash


# # #
# SETTINGS

email="iso@tmlmobilidade.pt"
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

primary_domain="go-stg.tmlmobilidade.pt"
wildcard_domain="*.$primary_domain"


# # #
# STARTUP

echo ">>> Cleaning letsencrypt directory..."
sudo rm -Rf "./letsencrypt/"

echo ">>> Downloading recommended TLS parameters ..."
mkdir -p "./letsencrypt"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "./letsencrypt/options-ssl-nginx.conf"
curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "./letsencrypt/ssl-dhparams.pem"
echo


# # #
# REQUEST CERTIFICATE

echo ">>> Preparing for "$primary_domain" and "$wildcard_domain"..."

echo ">>> Requesting Let's Encrypt certificate for "$primary_domain"..."
if [ $staging != "0" ]; then staging_arg="--staging"; fi # Enable staging mode if needed
docker compose run --rm --entrypoint "certbot certonly --dns-cloudflare --dns-cloudflare-credentials /run/secrets/cloudflaretoken -w /var/www/certbot $staging_arg -d $primary_domain -d $wildcard_domain --email $email --agree-tos --noninteractive --verbose --force-renewal" certbot
echo


# # #
# CLEANUP

echo ">>> Rebuilding nginx ..."
docker compose up -d --build --force-recreate --remove-orphans --pull=always
echo

echo ">>> DONE!"