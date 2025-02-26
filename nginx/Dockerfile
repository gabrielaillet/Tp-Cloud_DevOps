FROM nginx:latest
WORKDIR /app
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY nginxDebug.conf /etc/nginx/nginx.conf

