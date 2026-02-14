#!/bin/bash

# 定義安裝目錄
INSTALL_DIR="/opt/nv-dcgm-exporter"

echo "🚀 開始安裝 NVIDIA DCGM Exporter..."

# 1. 建立目錄
if [ ! -d "$INSTALL_DIR" ]; then
    echo "📂 建立目錄: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# 2. 寫入 custom.csv
echo "📝 正在寫入 custom.csv..."
cat <<EOF > custom.csv
# Format
# DCGM FIELD, Prometheus metric type, help message

# Clocks
DCGM_FI_DEV_SM_CLOCK,  gauge, SM clock frequency (in MHz).
DCGM_FI_DEV_MEM_CLOCK, gauge, Memory clock frequency (in MHz).

# Temperature
DCGM_FI_DEV_MEMORY_TEMP, gauge, Memory temperature (in C).
DCGM_FI_DEV_GPU_TEMP,    gauge, GPU temperature (in C).

# Power
DCGM_FI_DEV_POWER_USAGE,              gauge, Power draw (in W).
DCGM_FI_DEV_TOTAL_ENERGY_CONSUMPTION, counter, Total energy consumption since boot (in mJ).

# PCIE
DCGM_FI_DEV_PCIE_REPLAY_COUNTER, counter, Total number of PCIe retries.

# Utilization
DCGM_FI_DEV_GPU_UTIL,      gauge, GPU utilization (in %).
DCGM_FI_DEV_MEM_COPY_UTIL, gauge, Memory utilization (in %).
DCGM_FI_DEV_ENC_UTIL,      gauge, Encoder utilization (in %).
DCGM_FI_DEV_DEC_UTIL ,      gauge, Decoder utilization (in %).

# Errors and violations
DCGM_FI_DEV_XID_ERRORS,              gauge,  Value of the last XID error encountered.

# Memory usage
DCGM_FI_DEV_FB_FREE, gauge, Framebuffer memory free (in MiB).
DCGM_FI_DEV_FB_USED, gauge, Framebuffer memory used (in MiB).

# NVLink
DCGM_FI_DEV_NVLINK_BANDWIDTH_TOTAL,            counter, Total number of NVLink bandwidth counters for all lanes.

# VGPU License status
DCGM_FI_DEV_VGPU_LICENSE_STATUS, gauge, vGPU License status

# Remapped rows
DCGM_FI_DEV_UNCORRECTABLE_REMAPPED_ROWS, counter, Number of remapped rows for uncorrectable errors
DCGM_FI_DEV_CORRECTABLE_REMAPPED_ROWS,   counter, Number of remapped rows for correctable errors
DCGM_FI_DEV_ROW_REMAP_FAILURE,           gauge,   Whether remapping of rows has failed

# Static configuration information
DCGM_FI_DRIVER_VERSION,        label, Driver Version

# Datacenter Profiling (DCP) metrics
DCGM_FI_PROF_GR_ENGINE_ACTIVE,   gauge, Ratio of time the graphics engine is active.
DCGM_FI_PROF_SM_ACTIVE,          gauge, The ratio of cycles an SM has at least 1 warp assigned.
DCGM_FI_PROF_SM_OCCUPANCY,       gauge, The ratio of number of warps resident on an SM.
DCGM_FI_PROF_PIPE_TENSOR_ACTIVE, gauge, Ratio of cycles the tensor (HMMA) pipe is active.
DCGM_FI_PROF_DRAM_ACTIVE,        gauge, Ratio of cycles the device memory interface is active sending or receiving data.
DCGM_FI_PROF_PCIE_TX_BYTES,      gauge, The rate of data transmitted over the PCIe bus in bytes per second.
DCGM_FI_PROF_PCIE_RX_BYTES,      gauge, The rate of data received over the PCIe bus in bytes per second.
EOF

# 3. 寫入 docker-compose.yml
echo "🐳 正在寫入 docker-compose.yml..."
cat <<EOF > docker-compose.yml
services:
  dcgm-exporter:
    image: nvcr.io/nvidia/k8s/dcgm-exporter:4.5.2-4.8.1-ubuntu22.04
    container_name: dcgm-exporter
    restart: always
    ports:
      - "9400:9400"
    volumes:
      - /proc:/proc:rw
      - ./custom.csv:/etc/dcgm-exporter/custom.csv:ro
    command: ["-f","/etc/dcgm-exporter/custom.csv"]
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    environment:
      - DCGM_EXPORTER_INTERVAL=5000
    privileged: true
    pid: "host"
EOF

# 4. 啟動容器
echo "⚙️ 正在啟動 Docker 容器..."
docker compose up -d

# 5. 驗證
echo "✅ 安裝完成！"
echo "📊 檢查服務狀態: docker compose ps"
echo "🔗 Metrics 網址: http://localhost:9400/metrics"