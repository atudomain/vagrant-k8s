#!/usr/bin/env bash


SCRIPT='deploy_nginx.sh'


echo "[$SCRIPT] Deploy nginx"
helm install /vagrant/nginx --generate-name

