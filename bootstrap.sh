#!/usr/bin/env bash


SCRIPT='bootstrap.sh'


# SUPPRESS HARMLESS WARNINGS


export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
export DEBIAN_FRONTEND=noninteractive
sed -i '/net\.ipv4\.conf\.all\.promote_secondaries/d' /usr/lib/sysctl.d/50-default.conf


# SET BASE CONFIGURATION


echo "[$SCRIPT] Append to /etc/hosts"
cat <<EOF | tee /etc/hosts
172.17.17.10 master.example.com master
172.17.17.11 node1.example.com node1
172.17.17.12 node2.example.com node2
EOF

echo "[$SCRIPT] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[$SCRIPT] Configure iptables for bridged traffic"
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

echo "[$SCRIPT] Ensure br_netfilter is enabled"
echo 'br_netfilter' > /etc/modules-load.d/kubernetes.conf
modprobe br_netfilter


# INSTALL CONTAINERD


echo "[$SCRIPT] Install containerd"
apt-get update
apt-get install -y containerd

echo "[$SCRIPT] Configure system for containerd"
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system

echo "[$SCRIPT] Configure containerd with systemd cgroup driver"
mkdir -p /etc/containerd
cp -f /vagrant/containerd-config.toml /etc/containerd/config.toml

echo "[$SCRIPT] Enable and restart containerd to reload configuration"
systemctl enable containerd
systemctl restart containerd


# INSTALL KUBEADM, KUBECTL AND KUBELET


echo "[$SCRIPT] Install kubeadm (https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)"
apt-get update && apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet=1.20.0-00 kubeadm=1.20.0-00 kubectl=1.20.0-00
apt-mark hold kubelet kubeadm kubectl

echo "[$SCRIPT] Start and enable kubelet"
systemctl enable kubelet >/dev/null 2>&1
systemctl start kubelet >/dev/null 2>&1


# GENERATE SSL CERTIFICATES


echo "[$SCRIPT] Generate node certificates for ssl proxy deployment"
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=US/ST=Denial/L=Example/O=Example/CN=www.example.com" -keyout /etc/ssl/private/nginx.key -out /etc/ssl/private/nginx.crt > /dev/null 2>&1

