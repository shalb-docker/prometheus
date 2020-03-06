source ./helmfile-monitoring.yaml.d/secrets

cat ./helmfile-monitoring.yaml.d/secrets.yml.example | \
sed -e "s@{{ INGRESS_HTTP_AUTH }}@$INGRESS_HTTP_AUTH@g" \
> ./helmfile-monitoring.yaml.d/secrets.yml

kubectx "{{ CLUSTER_NAME }}" && kubectl apply -f ./helmfile-monitoring.yaml.d/secrets.yml

cat ./helmfile-monitoring.yaml.d/prometheus-operator/grafana_password.yml.example | \
sed -e "s@{{ GRAFANA_ADMIN_PASSWORD }}@$GRAFANA_ADMIN_PASSWORD@g" \
> ./helmfile-monitoring.yaml.d/prometheus-operator/grafana_password.yml

cat ./helmfile-monitoring.yaml.d/prometheus-operator/alertmanager_configs.yml.example | \
sed -e "s@{{ OPSGENIE_API_KEY }}@$OPSGENIE_API_KEY@g" | \
sed -e "s@{{ SLACK_API_URL }}@$SLACK_API_URL@g" \
> ./helmfile-monitoring.yaml.d/prometheus-operator/alertmanager_configs.yml

cat ./helmfile-monitoring.yaml.d/manifests/41_opsgenie-heartbeat_deployment.yml.example | \
sed -e "s@{{ OPSGENIE_API_KEY }}@$OPSGENIE_API_KEY@g" \
> ./helmfile-monitoring.yaml.d/manifests/41_opsgenie-heartbeat_deployment.yml

