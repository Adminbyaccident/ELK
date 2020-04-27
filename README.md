# ELK
This is a collection of ELK stack install and config scripts

## The elk-stack-v7_centos-8.sh script
This script installs an ELK stack version 7 on a single CenOS 8 server

It lacks TLS connections, so everything goes in plain text. Use it only on safe and/or internal networks.

## The elk-stack-v6_freebsd-12.sh script
This script install an ELK stack version 6 on a single FreeBSD 12 server

It lacks TLS connections, so everything goes in plain text. Use it only on safe and/or internal networks.

## The elk-stack-v6_security-freebsd-12.sh script
This script works in conjunction with the above one and allows the ELK stack to have:

- Fits an NGINX as a reverse proxy for Kibana which allows some niceties as described below
- TLS connections from the clients (browser, not the log collection) with self-signed key and certificate
- HTTP to HTTPS redirection
- Sets the HSTS header in NGINX so TLS connections can't be downgraded to plain text
- Sets username and password (at the beginning of the script you'll be asked to set a new password)
