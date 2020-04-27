#!/usr/bin/bash

# This is a script to secure an ELK stack version 6 on FreeBSD 12
# Use it after the original ELK stack script found in this URL:
# https://github.com/Adminbyaccident/ELK/blob/master/elk-stack-v6_freebsd-12.sh

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Add username and password to access Kibana through NGINX
echo "This is the only interactive bit on this script"
echo "Set the password you want for the kbadmin user. You'll be asked twice"
echo "kibadmin:`openssl passwd -apr1`" | sudo tee -a /usr/local/etc/nginx/htpasswd.users

# Install NGINX web server
pkg install -y nginx

# Include NGINX as a service to fire up at boot time
sysrc nginx_enable="YES"

# Rename default NGINX configuration. A customized one is found below.
mv /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/nginx.conf.original

# Create an empty default NGINX configuration file.
touch /usr/local/etc/nginx/nginx.conf

# Generate TLS self-signed key and certificate with OpenSSL

openssl genpkey -algorithm RSA -out /usr/local/etc/nginx/cert.key 
openssl req -new -x509 -days 365 -key cert.key -out /usr/local/etc/nginx/cert.crt -sha256 -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident/OU=Operations/CN=adminbyaccident.com"

# Configure NGINX (as a reverse proxy)
echo "

#user  nobody;
worker_processes  1;

# This default error log path is compiled-in to make sure configuration parsing
# errors are logged somewhere, especially during unattended boot when stderr
# isn't normally logged anywhere. This path will be touched on every nginx
# start regardless of error log location configured here. See
# https://trac.nginx.org/nginx/ticket/147 for more info. 
#
#error_log  /var/log/nginx/error.log;
#

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

server {
    listen 80;
    return 301 https://$host$request_uri;
}

server {

    listen 443 ssl;
    server_name localhost;

    auth_basic "Restricted Access";
    auth_basic_user_file /usr/local/etc/nginx/htpasswd.users;
    
    ssl_certificate           /usr/local/etc/nginx/cert.crt;
    ssl_certificate_key       /usr/local/etc/nginx/cert.key;

    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols   TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;
    
    access_log            /var/log/nginx/elk.log;
    add_header Strict-Transport-Security "max-age=63072000" always;


    location / {

      proxy_set_header        Host $host;
      proxy_set_header        X-Real-IP $remote_addr;
      proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $scheme;
      proxy_pass              http://localhost:5601;
      proxy_read_timeout      90;

      proxy_redirect      http://localhost:5601 https://$host$request_uri;
    }
  }

}
" >> /usr/local/etc/nginx/nginx.conf

# Create an empty log file to register the ELK accesses thorugh NGINX
touch /var/log/nginx/elk.log

# Stop Kibana
service kibana stop

# Wait a few seconds just in case Kibana doesn't stop immediately
sleep 15

# Reconfigure Kibana not to be accessed from anywhere but only from localhost
sed -ip 's/server.host: "0.0.0.0"/server.host: "127.0.0.1"/g' /usr/local/etc/kibana/kibana.yml

# Start Kibana again
service kibana start

# Wait a few seconds for Kibana to get ready
sleep 15

# Start NGINX web server
service nginx start

# Final message
echo "The ELK stack access on this system has been secured with an NGINX reverse proxy with TLS and local authentication with username and password."

# EOF
