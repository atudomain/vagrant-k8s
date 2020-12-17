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


# INSTALL DOCKER


echo "[$SCRIPT] Install Docker"
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
apt-get install -y containerd.io docker-ce docker-ce-cli

echo "[$SCRIPT] Configure Docker runtime to use systemd cgroup" 
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

echo "[$SCRIPT] Start and enable Docker" 
systemctl daemon-reload >/dev/null 2>&1
systemctl enable docker >/dev/null 2>&1
systemctl restart docker >/dev/null 2>&1


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

