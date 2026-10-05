# devops_learning

Bastion prep:
sudo apt update
sudo apt install -y ansible git make pipx
ansible --version

pipx ensurepath
pipx install ansible-lint
pipx install yamllint
exec bash

~/.ssh/config:
Host master
  HostName 192.168.10.100
Host worker1
  HostName 192.168.10.111
Host worker2
  HostName 192.168.10.112
Host master worker1 worker2
  User vagrant
  IdentityFile ~/.ssh/id_ed25519
  StrictHostKeyChecking accept-new

ANSIBLE.CFG
host_key_checking = False - only for test in homelab