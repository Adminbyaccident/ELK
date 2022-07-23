#!/bin/sh
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: elk-stack-v7_freebsd-13.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 21-07-2022
# SET FOR: Test
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: FreeBSD 13
#
# PURPOSE: This script installs the ELK stack version 7 on a FreeBSD 13system
#
# REV LIST:
# DATE: 
# BY: ALBERT VALBUENA
# MODIFICATION: 
#
#
# set -n # Uncomment to check your syntax, without execution.
# # NOTE: Do not forget to put the comment back in or
# # the shell script will not execute!

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

# Change the default pkg repository from quarterly to latest
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install Java (Check versions on this matrix: https://www.elastic.co/support/matrix#matrix_jvm)
pkg install -y openjdk11

# Mount fdescfs and procfs file systems
# If the permanent configuration below is not set problems may raise after reboots
mount -t fdescfs fdesc /dev/fd
mount -t procfs proc /proc

# Configure OpenJDK for FreeBSD (permanent)
echo "
fdesc   /dev/fd         fdescfs         rw      0       0
proc    /proc           procfs          rw      0       0
" >> /etc/fstab

# Install Elasticsearch version 7
pkg install -y elasticsearch7

# Configure Elasticsearch
sed -ip 's/#network.host: 192.168.0.1/network.host: localhost/g' /usr/local/etc/elasticsearch/elasticsearch.yml

sed -ip 's/#http.port:/http.port:/g' /usr/local/etc/elasticsearch/elasticsearch.yml

sed -ip 's/#cluster.initial_master_nodes: \["node-1", "node-2"\]/cluster.initial_master_nodes: \["localhost"\]/g' /usr/local/etc/elasticsearch/elasticsearch.yml

# ElasticSearch requires memory locking of large amounts of RAM.
sysctl security.bsd.unprivileged_mlock=1

# Enable the Elasticsearch service
sysrc elasticsearch_enable="YES"

# Start up the Elasticsearch service
service elasticsearch start


# Install Logstash version 7
pkg install -y logstash7

# Configure Logstash
sed -ip 's/# http.host/http.host/g'  /usr/local/etc/logstash/logstash.yml

# Enable the Logstash service
sysrc logstash_enable="YES"

# Start up the Logstash service
service logstash start


# Install Kibana version 7
pkg install -y kibana7

# Configure Kibana
sed -ip 's/#server.host: "localhost"/server.host: "0.0.0.0"/g' /usr/local/etc/kibana/kibana.yml

sed -ip 's/#server.port: 5601/server.port: 5601/g' /usr/local/etc/kibana/kibana.yml

# Enable the Kibana service
sysrc kibana_enable="YES"

# Start up the Kibana service
service kibana start

# Final message 1
echo "ELK stack installed"

# Final message 2
echo "Visit this URL 'http://yourserverip:5601' in order to use the ELK stack"

#Final message 3
echo "Mind to restrict access and configure TLS communication to your ELK stack since it comes with no security enabled by default"

#Final message 4
echo "For more security configuration details please visit the following link https://www.elastic.co/guide/en/elasticsearch/reference/7.16/configuring-stack-security.html"
