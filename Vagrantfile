Vagrant.configure("2") do |config|


  config.vm.provision :shell, path: "bootstrap.sh"


  # Master

  config.vm.define "master" do |master|
    master.vm.box = "bento/ubuntu-20.04"
    master.vm.hostname = "master.example.com"
    master.vm.network "private_network", ip: "172.17.17.10", :netmask => "255.255.255.0"
    master.vm.provider "virtualbox" do |v|
      v.name = "master"
      v.memory = 2048
      v.cpus = 2
    end
    master.vm.provision :shell, path: "bootstrap_master.sh"
    master.vm.provision :shell, path: "deploy_nginx.sh"
    master.vm.network :forwarded_port, guest: 30003, host: 6080
  end


  # Slave nodes

  NodeCount = 2

  (1..NodeCount).each do |i|
    config.vm.define "node#{i}" do |node|
      node.vm.box = "bento/ubuntu-20.04"
      node.vm.hostname = "node#{i}.example.com"
      node.vm.network "private_network", ip: "172.17.17.1#{i}", :netmask => "255.255.255.0"
      node.vm.provider "virtualbox" do |v|
        v.name = "node#{i}"
        v.memory = 1024
        v.cpus = 1
      end
      node.vm.provision :shell, path: "bootstrap_node.sh"
    end
  end

end
