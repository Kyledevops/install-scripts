#!/bin/bash
if ! id -u node_exporter &>/dev/null; then
    sudo useradd --system --shell /bin/false node_exporter || echo -e "Failed to add user"
fi

LATEST_VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep "tag_name" | awk '{print $2}' | tr -d '",' | sed 's/^v//') && \

curl -sSL https://github.com/prometheus/node_exporter/releases/download/v${LATEST_VERSION}/node_exporter-${LATEST_VERSION}.linux-amd64.tar.gz | \
sudo tar -xz -C /usr/local/bin --strip-components=1 node_exporter-${LATEST_VERSION}.linux-amd64/node_exporter 

sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

sudo tee /etc/systemd/system/node_exporter.service  > /dev/null <<EOF
[Unit]
Description=Node Exporter

[Service]
User=node_exporter
Group=node_exporter
Environment=OPTIONS=
EnvironmentFile=-/etc/sysconfig/node_exporter
ExecStart=/usr/local/bin/node_exporter $OPTIONS

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter