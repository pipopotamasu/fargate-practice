FROM nginx:1.15-alpine

COPY nginx /etc/nginx/conf.d
COPY entrypoint.sh /entrypoint.sh

# CMD は entrypoint.sh で上書き
CMD [ "/bin/sh", "/entrypoint.sh" ]