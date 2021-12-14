#!/usr/bin/bash
# Instructions on how to use this script:
# chmod +x SCRIPTNAME.sh
# sudo ./SCRIPTNAME.sh
#
# SCRIPT: elk-stack-v7_centos-8.sh
# AUTHOR: ALBERT VALBUENA
# DATE: 26-04-2020
# SET FOR: Production
# (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: CentOS 8
#
# PURPOSE: This script installs an ELK stack version 7 on CentOS 8
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

# Let's update CentOS local repositories on this box.
yum update -y

# Let's upgrade the already installed packages on this box.
yum upgrade -y

# Allow Kibana through the firewall
firewall-cmd --permanent --zone=public --add-port=5601/tcp
# Allow Logstash to get logs from Beats on the client through port 5044
firewall-cmd --permanent --zone=public --add-port=5044/tcp
# Reload the firewall rules
firewall-cmd --reload

# Enable EPEL repository
yum --enablerepo=extras install epel-release

# Install Java
yum install -y java-latest-openjdk.x86_64

# Import Elastic's repository key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Add a configuration file for the elasticsearch repository
echo "
[elasticsearch]
name=Elasticsearch repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=0
autorefresh=1
type=rpm-md
" >> /etc/yum.repos.d/elasticsearch.repo

# Enable the just configured repo
yum install -y --enablerepo=elasticsearch elasticsearch

# Configure elasticsearch itself
sed -i 's/#network.host: 192.168.0.1/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml

sed -i 's/#http.port:/http.port:/' /etc/elasticsearch/elasticsearch.yml

# Enable elasticsearch as a service controlled by systemd
systemctl enable elasticsearch.service

# Start elasticsearch
systemctl start elasticsearch.service

# Add a configuration file for the logstash repository
echo "
[logstash-7.x]
name=Elastic repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
" >> /etc/yum.repos.d/logstash.repo

# Install logstash
yum install -y logstash

# Configure logstash itself
sed -i 's/#http.host: "127.0.0.1"/http.host:"127.0.0.1"/'  /etc/logstash/logstash.yml

# Enable logstash as a service controlled by systemd
systemctl enable logstash.service

# Start up logstash
systemctl start logstash.service

# Add a configuration file for the kibana repository
echo "
[kibana-7.x]
name=Kibana repository for 7.x packages
baseurl=https://artifacts.elastic.co/packages/7.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
" >> /etc/yum.repos.d/kibana.repo

# Install kibana
yum install -y kibana

# Configure kibana itself
sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml

sed -i 's/#server.port: 5601/server.port: 5601/' /etc/kibana/kibana.yml

# Enable kibana as a service controlled by systemd
systemctl enable kibana.service

# Start up kibana
systemctl start kibana.service

# Final message 1
echo "ELK stack installed"

# Final message 2
echo "Visit this URL 'http://yourserverip:5601' in order to use the ELK stack"
