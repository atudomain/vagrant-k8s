#!/usr/bin/env bash


SCRIPT='bootstrap_node.sh'


# JOIN SLAVE NODE TO CLUSTER


echo "[$SCRIPT] Join node to the cluster"
bash /vagrant/data-master/join-command.sh > /root/join.log 2>&1

