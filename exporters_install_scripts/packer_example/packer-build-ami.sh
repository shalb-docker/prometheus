#!/bin/bash
export PACKER_LOG=3
export PACKER_LOG_PATH="packer.log"
packer_args=$*


packer build -force ${packer_args} ami.json
