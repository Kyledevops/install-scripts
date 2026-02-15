#!/bin/bash
set -e

# --- Configuration ---
VECTOR_VERSION="0.53.0"
VICTORIALOGS_HOST="us-vlinsert.aiaipool.com"
VICTORIALOGS_PORT="80"
# 自動偵測 IP，優先使用環境變數
HOST_IP="${HOST_IP:-$(hostname -I | cut -d' ' -f1)}"

INSTALL_DIR="/usr/bin"
CONFIG_DIR="/etc/vector"
DATA_DIR="/var/lib/vector"
VECTOR_CONFIG="$CONFIG_DIR/vector.toml"

# 檢查是否為 root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ 請使用 sudo 執行此腳本"
  exit 1
fi

echo "🚀 開始安裝 Vector v${VECTOR_VERSION}..."

# 1. 自動判斷系統架構並下載
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  TARGET="x86_64-unknown-linux-musl" ;;
    aarch64) TARGET="aarch64-unknown-linux-musl" ;;
    *) echo "❌ 不支援的架構: $ARCH"; exit 1 ;;
esac

echo "📥 下載 Vector 二進位檔 (${TARGET})..."
URL="https://packages.timber.io/vector/${VECTOR_VERSION}/vector-${VECTOR_VERSION}-${TARGET}.tar.gz"
curl -L $URL | tar xz --strip-components=2 -C /tmp
mv /tmp/bin/vector $INSTALL_DIR/
chmod +x $INSTALL_DIR/vector

# 2. 建立使用者與目錄權限
if ! id -u vector > /dev/null 2>&1; then
    useradd -r -m -s /bin/false vector
fi
# 為了讀取 Docker logs，將 vector 加入 docker 群組
if getent group docker > /dev/null; then
    usermod -aG docker vector
fi

mkdir -p $CONFIG_DIR $DATA_DIR
chown -R vector:vector $DATA_DIR

# 3. 寫入 Vector 設定檔 (TOML 格式)
echo "📝 配置 Vector 設定檔..."
cat <<EOF > "$VECTOR_CONFIG"
data_dir = "$DATA_DIR"

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
  .host_ip = "${HOST_IP}"
'''

[sinks.victoria_logs]
type = "http"
inputs = ["enrich_host_info"]
uri = "http://${VICTORIALOGS_HOST}:${VICTORIALOGS_PORT}/insert/jsonline?_stream_fields=stream,host,host_ip,container_name&_msg_field=message&_time_field=timestamp"
compression = "zstd"

  [sinks.victoria_logs.encoding]
  codec = "json"

  [sinks.victoria_logs.framing]
  method = "newline_delimited"

  [sinks.victoria_logs.healthcheck]
  enabled = true
EOF

chown vector:vector "$VECTOR_CONFIG"

# 4. 建立 Systemd Service (整合官方安全參數)
echo "⚙️ 建立 Systemd 服務..."
cat <<EOF > /etc/systemd/system/vector.service
[Unit]
Description=Vector
Documentation=https://vector.dev
After=network-online.target docker.service
Requires=network-online.target

[Service]
User=vector
Group=vector
# 啟動前檢查設定檔語法
ExecStartPre=$INSTALL_DIR/vector validate --config-toml $VECTOR_CONFIG
ExecStart=$INSTALL_DIR/vector --config-toml $VECTOR_CONFIG
ExecReload=$INSTALL_DIR/vector validate --config-toml $VECTOR_CONFIG
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
AmbientCapabilities=CAP_NET_BIND_SERVICE

# 安全沙盒設定
ProtectSystem=full
ProtectHome=yes
PrivateTmp=yes
NoNewPrivileges=yes
ReadOnlyPaths=/
ReadWritePaths=$DATA_DIR

[Install]
WantedBy=multi-user.target
EOF

# 5. 啟動服務
echo "🔄 載入並啟動 Vector..."
systemctl daemon-reload
systemctl enable vector
systemctl restart vector

echo "-----------------------------------------"
echo "✅ Vector 安裝與配置完成！"
echo "🌐 傳送目標: ${VICTORIALOGS_HOST}:${VICTORIALOGS_PORT}"
echo "📡 本機 IP: ${HOST_IP}"
echo "📊 API 地址: http://localhost:8686"
echo "📝 查看日誌: journalctl -u vector -f"

echo "-----------------------------------------"
echo "💡 如何在 Docker Compose 中啟用日誌採集？"
echo "-----------------------------------------"
echo "請在你的 docker-compose.yml 服務中加入 'labels: ['log=true']'"
echo ""
echo "services:"
echo "  your-app:"
echo "    image: your-image"
echo "    container_name: my-app-name  # 建議固定名稱，方便儀表板搜尋"
echo "    labels:"
echo '      - log=true             # 必須有這行，Vector 才會抓取'
echo ""
echo "範例："
echo "  echo 'labels: ['log=true']' >> docker-compose.yml"
echo "-----------------------------------------"