#!/bin/sh

# This is an install script for an ELK stack version 6 on FreeBSD 12.1
# Version 7 of the stack fails to start Kibana (known issue)

# Instructions on how to use this script 

# chmod +x SCRIPTNAME.sh

# sudo ./SCRIPTNAME.sh

# Change the default pkg repository from quarterly to latest
sed -ip 's/quarterly/latest/g' /etc/pkg/FreeBSD.conf

# Update packages (it will first download the pkg repo from latest)
# secondly it will upgrade any installed packages.
pkg upgrade -y

# Install Java (Check versions on this matrix: https://www.elastic.co/support/matrix#matrix_jvm)
pkg install -y openjdk8

# Mount fdescfs and procfs file systems
# If the permanent configuration below is not set problems may raise after reboots
mount -t fdescfs fdesc /dev/fd
mount -t procfs proc /proc

# Configure OpenJDK for FreeBSD (permanent)
echo "
fdesc   /dev/fd         fdescfs         rw      0       0
proc    /proc           procfs          rw      0       0
" >> /etc/fstab

# Install Elasticsearch version 6
pkg install -y elasticsearch6

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


# Install Logstash version 6
pkg install -y logstash6

# Configure Logstash
sed -ip 's/# http.host/http.host/g'  /usr/local/etc/logstash/logstash.yml

# Enable the Logstash service
sysrc logstash_enable="YES"

# Start up the Logstash service
service logstash start


# Install Kibana version 6
pkg install -y kibana6

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
