#!/bin/bash
set -e

# Configuration
VICTORIALOGS_HOST="us-vlinsert.aiaipool.com"
VICTORIALOGS_PORT="80"
# Allow user to override HOST_IP, otherwise try to detect source IP for routing to VL
HOST_IP="${HOST_IP:-$(hostname -I | cut -d' ' -f1)}"
VECTOR_CONFIG="/etc/vector/vector.toml"

echo "Installing Vector..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.vector.dev | bash -s -- -y

echo "Configuring Vector..."
mkdir -p /etc/vector

cat <<EOF > "$VECTOR_CONFIG"
[api]
enabled = true
address = "0.0.0.0:8686"

[sources.docker_logs]
type = "docker_logs"
include_labels = ["log=true"]

[transforms.enrich_host_info]
type = "remap"
inputs = ["docker_logs"]
source = '''
  .host_name = get_hostname!()
  .host_ip = "${HOST_IP}"
  # container_name is already provided by docker_logs source
'''

[sinks.victoria_logs]
type = "http"
inputs = ["enrich_host_info"]
# Added host_name, host_ip, and container_name to _stream_fields for the dashboard
uri = "http://${VICTORIALOGS_HOST}:${VICTORIALOGS_PORT}/insert/jsonline?_stream_fields=stream,host_name,host_ip,container_name&_msg_field=message&_time_field=timestamp"
encoding.codec = "json"
framing.method = "newline_delimited"
compression = "zstd" # Changed to zstd as requested

[sinks.victoria_logs.healthcheck]
enabled = true
EOF

echo "Reloading Systemd and Restarting Vector..."
systemctl enable vector
systemctl restart vector

echo "Vector setup complete!"
echo "Logs sending to: ${VICTORIALOGS_HOST}:${VICTORIALOGS_PORT}"
echo "Detected Host IP: ${HOST_IP} (Override with HOST_IP=x.x.x.x sudo ./setup_vector.sh if incorrect)"