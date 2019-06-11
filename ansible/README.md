# Install Ansible

~~~~
apt install python-pip
pip install ansible
ssh-keygen
cp -r ansible/ /data/ansible/
ln -s /data/ansible ~/ansible
ln -s /data/ansible/.ansible.cfg ~/.ansible.cfg
~~~~

# Configure Ansible

## Customize configuration file if user not "root", etc

~~~~
editor /data/ansible/.ansible.cfg
~~~~

## Add your hosts

~~~~
editor /data/ansible/hosts
~~~~

## Check connectivity

~~~~
export ANSIBLE_HOST_KEY_CHECKING="False"
ansible -m shell -a 'ls -lad /root/.ssh' all
~~~~

## Apply roles

~~~~
ansible-playbook main.yml
~~~~

