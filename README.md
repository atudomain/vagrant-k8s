# Overview 

Example of Kubernetes cluster automated with Vagrant:
- Vagrant provisioner: VirtualBox (available on most of operating systems)
- Bootstrapping: kubeadm (https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)
- Nodes operating system: Ubuntu 20.04
- Networking: Weave Net
- Container runtime: containerd with systemd as cgroup driver
- Number of nodes: 1 master and 2 slaves

Contains Helm chart of Nginx proxy that serves https://infconfig.co over http. Port is exposed externally on master node virtual machine using Kubernetes node port and Vagrant port forwarding. It would be more flexible to use an ingress in production evironment.

# Requirements

- VirtualBox (https://www.virtualbox.org/) 
- Vagrant (https://www.vagrantup.com/)
- git
- curl
- port 6080 cannot be used on local machine, as it is required to access proxy from outside

# Usage

## Clone the repository
```
git clone https://github.com/atu-repo/k8s-vagrant.git
```
The rest of instruction assumes you are in root of that cloned repository.

## Initialize the cluster
```
vagrant up
```
Wait for the process to finish. There should be no errors nor warnings printed, but it takes some time to download and install required packages.

## Get kube config file with cluster credentials
It is stored locally after cluster initialisation in newly created directory 'data-master' as 'admin.conf' file.

## Access ifconfig.co using deployed Nginx proxy
If everything completed successfully up to this point, you should be able to run:
```
curl http://127.0.0.1:6080
```
and get your public IP as proxied response from https://ifconfig.co.

## Check Helm chart with the deployment of Nginx proxy
Helm chart is located in 'nginx' directory. The command used to install it can be found in 'deploy_nginx.sh' script.
It was created from template and modifed. Config file is read as configMap and mounted as volume, also certificates generated on nodes and are mounted as Directory type. Service was changed to nodePort with specified port.

## Access cluster
Connect to master node:
```
vagrant ssh master
```
To connect to slave nodes use 'node1' and 'node2' names.
Once you are on master, switch to root:
```
sudo su -
```
Now you can use kubectl to check cluster nodes, for example:
```
kubectl get nodes
```

## Remove virtual machines with cluster
Log out from nodes and run:
```
vagrant destroy
```
