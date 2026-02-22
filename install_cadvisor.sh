#!/bin/bash
# 1. 定義版本與路徑
CADVISOR_VERSION="0.56.2"
INSTALL_DIR="/opt/cadvisor"
COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"

echo "🚀 開始安裝 cAdvisor $CADVISOR_VERSION..."

# 2. 建立安裝目錄
sudo mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 3. 產出 docker-compose.yml
cat <<EOF | sudo tee $COMPOSE_FILE
services:
  cadvisor:
    image: ghcr.io/google/cadvisor:$CADVISOR_VERSION
    container_name: cadvisor
    privileged: true
    command:
      - --port=9200
    devices:
      - /dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "9200:9200"
    restart: always
    deploy:
      resources:
        limits:
          memory: 512M
EOF

# 5. 啟動服務
echo "⚙️ 正在啟動 cAdvisor 容器..."
sudo docker-compose up -d

# 6. 驗證狀態
if [ "$(sudo docker inspect -f '{{.State.Running}}' cadvisor)" == "true" ]; then
    echo "✅ cAdvisor 安裝成功！"
    echo "🌐 存取位址: http://localhost:9200"
    echo "📊 Prometheus Metrics: http://localhost:9200/metrics"
else
    echo "❌ 安裝失敗，請檢查 docker logs cadvisor"
    docker logs cadvisor
fi