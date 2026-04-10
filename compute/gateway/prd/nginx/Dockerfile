# # #

FROM nginx:alpine-slim


# # #
# APPLICATION SETUP

WORKDIR /app


# # #
# BUILD NGINX CONFIGURATION FILE

COPY ./compute/gateway/prd/nginx/nginx.conf /etc/nginx/nginx.conf


# # #
# RUN NGINX WITH AUTO RELOAD

CMD ["/bin/sh", "-c", "while :; do sleep 6h & wait ${!}; nginx -s reload; done & nginx -g 'daemon off;'"]
