logger "running /opt/equinix/metal/bin/metal_monitoring_mangle.sh"
source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh

if [[ "$MINIO_INSTANCE" != 2 ]]; then
    logger "only mangle monitoring on node 2"
    exit 0
fi
if test ! -f /opt/equinix/metal/tmp/metal_monitoring_mangle.lock; then
    mv /etc/prometheus/prometheus.yml /opt/equinix/metal/tmp/prometheus.yml.orig
    sudo mkdir -p /etc/apt/keyrings/
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
    apt-get update
    apt-get install -y grafana
    touch /opt/equinix/metal/tmp/metal_monitoring_mangle.lock
else
    true
fi
TARGETS_STR=""
for i in $(seq 2 $NUM_INSTANCES); do
    INSTANCE_STR="\"$HOST_TYPE-$i.private:9100\","
    TARGETS_STR="${TARGETS_STR} $INSTANCE_STR"
done

CLEAN_TARGETS_STR=${TARGETS_STR::-1}
cat > /etc/default/prometheus << EOL
ARGS="--web.listen-address=:9005"
EOL

cat > /etc/prometheus/prometheus.yml << EOL
global:

  external_labels:
      monitor: 'example'

alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

rule_files:

scrape_configs:
  - job_name: 'prometheus'

    scrape_interval: 5s
    scrape_timeout: 5s


    static_configs:
      - targets: ['localhost:9005']

  - job_name: node
    static_configs:
      - targets: ['localhost:9100']

  - job_name: "remote_collector"
    scrape_interval: 10s
    static_configs:
      - targets: [$CLEAN_TARGETS_STR]

EOL
if test -f /opt/equinix/metal/tmp/minio_scrape_config.yaml; then
    BEARER_TOKEN=$(grep bearer_token /opt/equinix/metal/tmp/minio_scrape_config.yaml | awk '{print $2}')
    cat >> /etc/prometheus/prometheus.yml << EOL
  - job_name: minio-job
    bearer_token: $BEARER_TOKEN
    metrics_path: /minio/v2/metrics/cluster
    scheme: https
    tls_config:
      server_name: object.private
      insecure_skip_verify: true
    static_configs:
    - targets: ['127.0.0.1:9000']

EOL
fi

mkdir -p /var/lib/grafana/dashboards
rsync -a /opt/equinix/metal/tmp/metal_mnmd/etc/grafana/dashboards/ /var/lib/grafana/dashboards/
rsync -a /opt/equinix/metal/tmp/metal_mnmd/etc/grafana/datasources/ /etc/grafana/provisioning/datasources/
rsync /opt/equinix/metal/tmp/metal_mnmd/etc/grafana/object_private.yaml /etc/grafana/provisioning/dashboards/
chown grafana:grafana /var/lib/grafana/dashboards



systemctl stop prometheus
systemctl stop grafana-server
sleep 1
systemctl enable --now prometheus
systemctl enable --now grafana-server
