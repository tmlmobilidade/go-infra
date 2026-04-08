# # #

FROM nginx:alpine-slim


# # #
# APPLICATION SETUP

WORKDIR /app


# # #
# Install envsubst for variable substitution

RUN apk add --no-cache gettext


# # #
# BUILD NGINX CONFIGURATION FILE

COPY ./compute/gateway/stg/nginx/nginx.conf /etc/nginx/nginx.conf


# # #
# RUN NGINX WITH AUTO RELOAD

CMD ["/bin/sh", "-c", "while :; do sleep 6h & wait ${!}; nginx -s reload; done & nginx -g 'daemon off;'"]
