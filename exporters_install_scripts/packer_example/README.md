# 1. Build the universal AMI.

## Install packer

```
apt install unzip
wget https://releases.hashicorp.com/packer/1.4.2/packer_1.4.2_linux_amd64.zip
unzip packer_1.4.2_linux_amd64.zip
mv packer /usr/local/bin/packer
```

## Install aws cli

```
pip3 install awscli
```

## Setup your AMS access parameters in ~/.aws (add key)

```
aws configure
```


## Adjust Packer variables if nedded

```
vim ami.json
```

## Build the AMI

```
./packer-build-ami.sh

```

