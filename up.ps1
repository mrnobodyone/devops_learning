vagrant up
vagrant ssh bastion -c "cd ~/devops_learning && git pull && make provision"
