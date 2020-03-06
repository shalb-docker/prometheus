# Install particular helm version

Regarding to https://github.com/helm/charts/issues/17261

~~~~
wget https://get.helm.sh/helm-v2.14.3-linux-amd64.tar.gz
tar -xzf helm-v2.14.3-linux-amd64.tar.gz
mkdir -p ~/bin/
mv linux-amd64/helm ~/bin/helm
chmod 755 ~/bin/helm
export PATH="~/bin:$PATH"
~~~~

# Add secrets

Create 'secrets' file and apply if deploy first time.

If stack configured already, then copy secrets from wiki and apply (see secrets here https://confluence.shalb.com/pages/viewpage.action?spaceKey={{ PROJECT }}&title=Access#Access-{{ ENV }})

~~~~
cp ./helmfile-monitoring.yaml.d/secrets.example ./helmfile-monitoring.yaml.d/secrets
editor ./helmfile-monitoring.yaml.d/secrets
bash ./helmfile-monitoring.yaml.d/add_secrets.sh
~~~~

# Kustomize ingress configs

In most cases ingress configs have some differences per customer, fing and customize each config:

~~~~
ls -la ./helmfile-monitoring.yaml.d/prometheus-operator/*_ingress.yml
~~~~

# Deploy charts

Check helm diff results and apply configuraton:

~~~~
kubectx "{{ CLUSTER_NAME }}" && helmfile --file ./helmfile-monitoring.yaml diff
~~~~

Replace 'diff' by 'apply' and run it again, if all ok

# Deploy opsgenie heartbeat (prod cluster only)

Create opsgenie heartbeat which needed for alerting in case of dead monitoring

~~~
kubectx "{{ CLUSTER_NAME }}" && kubectl apply -f ./helmfile-monitoring.yaml.d/manifests/
~~~

Enable opsgenie heartbeat scrape - uncomment job_name: 'opsgenie-heartbeat local'

~~~
editor helmfile-monitoring.yaml.d/prometheus-operator/prometheus_scrape_configs.yml
kubectx "{{ CLUSTER_NAME }}" && helmfile --file ./helmfile-monitoring.yaml diff
~~~

Replace 'diff' by 'apply' and run it again, if all ok


