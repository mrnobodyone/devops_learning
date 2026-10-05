NODES = {
  "bastion" => { ip: "192.168.10.10",  cpus: 1, memory: 2048 },
  "master"  => { ip: "192.168.10.100", cpus: 1, memory: 2048 },
  "worker1" => { ip: "192.168.10.111", cpus: 1, memory: 2560 },
  "worker2" => { ip: "192.168.10.112", cpus: 1, memory: 2560 },
}

PUBKEY = File.read(File.join(__dir__, "keys", "ansible_ed25519.pub")).strip

Vagrant.configure("2") do |config|
  config.vm.boot_timeout = 600
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true

  NODES.each do |name, n|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: n[:ip]

      node.vm.provider "virtualbox" do |vb|
        vb.name = "homelab-#{name}"
        vb.cpus = n[:cpus]
        vb.memory = n[:memory]
        vb.linked_clone = true
      end

      # публичный ключ Ansible на всех ВМ (идемпотентно)
      node.vm.provision "shell", args: [PUBKEY], inline: <<~SH
        grep -qxF "$1" ~vagrant/.ssh/authorized_keys || echo "$1" >> ~vagrant/.ssh/authorized_keys
      SH

      # приватный ключ только на bastion
      if name == "bastion"
        node.vm.provision "file",
          source: "keys/ansible_ed25519",
          destination: "/home/vagrant/.ssh/id_ed25519"
        node.vm.provision "shell", privileged: false,
          inline: "chmod 600 ~/.ssh/id_ed25519"
        node.vm.provision "shell", privileged: false, inline: <<~SH
          sudo apt-get update -qq
          sudo apt-get install -y -qq ansible git make pipx
          pipx install ansible-lint || true
          pipx install yamllint || true
          [ -d ~/devops_learning ] || git clone https://github.com/mrnobodyone/devops_learning.git ~/devops_learning
        SH
      end
    end
  end
end