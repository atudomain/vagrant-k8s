#!/usr/bin/env bash


SCRIPT='bootstrap_master.sh'


# SETUP KUBERNETES ON MASTER


echo "[$SCRIPT] Initialize cluster"
kubeadm init --config=/vagrant/kubeadm.yaml > /root/kubeinit.log 2>&1

echo "[$SCRIPT] Setup kube credentials"
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chown -R root:root /root/.kube
mkdir -p /vagrant/data-master
cat /etc/kubernetes/admin.conf > /vagrant/data-master/admin.conf

echo "[$SCRIPT] Deploy weave network"
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

echo "[$SCRIPT] Store cluster join command"
kubeadm token create --print-join-command > /vagrant/data-master/join-command.sh

echo "[$SCRIPT] Install helm"
curl -fsSL -o /root/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 /root/get_helm.sh
bash /root/get_helm.sh

