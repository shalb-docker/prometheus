# How to create monitoring configuration for new cluster

## Create secrets file

~~~~
cp secrets.example secrets
~~~~

## Update secrets file regarding to your needs

~~~~
editor secrets
~~~~

## Run script to crate new configs from templates

Script will create configs in directory name "$CLUSTER_NAME", regarding to value from secrets file

~~~~
bash ./create_monitoring_for_cluster.sh
~~~~

## Customize new configuration

Customize configuration which created by the script

Copy it to appropriate place in git repo, for example:

~~~~
source secrets
mkdir -p ../${ENV}/kubernetes/
mv ${CLUSTER_NAME}/kubernetes/* ../${ENV}/kubernetes/
rmdir ${CLUSTER_NAME}/kubernetes && rmdir ${CLUSTER_NAME}
~~~~

## Apply configuration

Read README file to get further instructions:

~~~~
cd ../${ENV}/kubernetes/
less helmfile-monitoring.yaml.d/README.md
~~~~

