#!/bin/bash

# install ansible and apply to localhost
apt install -y python3-pip
pip3 install ansible
rsync -a /data/monitoring/prometheus/ansible/ /data/ansible/
ln -s /data/ansible /root/ansible
ln -s /data/ansible/.ansible.cfg /root/.ansible.cfg
cd /data/ansible/playbooks/
ssh-keygen
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
export ANSIBLE_HOST_KEY_CHECKING="False"
ansible-playbook main.yml

