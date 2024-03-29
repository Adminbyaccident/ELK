#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: elk-stack-v7_security_centos-8.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 28-04-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS 8
#
# PURPOSE: This script gives basic security to an ELK stack version 7 on CentOS 8
#
# REV LIST:
# DATE: 14-12-2021
# BY: ALBERT VALBUENA
# MODIFICATION: 14-12-2021
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Add username and password to access Kibana through NGINX
echo "This is the only interactive bit on this script"
echo "Set the password you want for the kbadmin user. You'll be asked twice"
echo "kibadmin:`openssl passwd -apr1`" | sudo tee -a /etc/nginx/htpasswd.users

# Change firewall ports
firewall-cmd --permanent --zone=public --remove-port=5601/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --reload

# Update the system
dnf update -y

# Install NGINX
dnf install -y nginx

# Enable NGINX on systemd management
systemctl enable nginx.service

# Rename default NGINX configuration. A customized one is found below.
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.original

# Create an empty default NGINX configuration file.
touch /etc/nginx/nginx.conf

# Generate TLS self-signed key and certificate with OpenSSL

openssl genpkey -algorithm RSA -out /etc/nginx/cert.key 
openssl req -new -x509 -days 365 -key /etc/nginx/cert.key -out /etc/nginx/cert.crt -sha256 -subj "/C=ES/ST=Barcelona/L=Terrassa/O=Adminbyaccident/OU=Operations/CN=adminbyaccident.com"
openssl dhparam -out /etc/nginx/dhparam.pem 2048

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
    listen 80 default_server;
    listen [::]:80 default_server;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;
    
    ssl_certificate           /etc/nginx/cert.crt;
    ssl_certificate_key       /etc/nginx/cert.key;
    ssl_session_timeout 1d;
    ssl_session_cache  builtin:1000  shared:SSL:10m;
    ssl_protocols   TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_tickets off;
    ssl_dhparam     /etc/nginx/dhparam.pem
    
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
" >> /etc/nginx/nginx.conf

# Create an empty log file to register the ELK accesses thorugh NGINX
touch /var/log/nginx/elk.log

# Stop Kibana
systemctl stop kibana.service

# Wait a few seconds just in case Kibana doesn't stop immediately
sleep 15

# Reconfigure Kibana not to be accessed from anywhere but only from localhost
sed -i 's/server.host: "0.0.0.0"/server.host: "127.0.0.1"/' /etc/kibana/kibana.yml

# Start Kibana again
systemctl start kibana.service

# Wait a few seconds for Kibana to get ready
sleep 15

# Start NGINX web server
systemctl start nginx

# Allow NGINX through SELinux
setsebool -P httpd_can_network_connect 1

# Final message
echo "The ELK stack access on this system has been secured with an NGINX reverse proxy with TLS and local authentication with username and password."

# EOF
