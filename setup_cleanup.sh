cat << 'EOF' > /tmp/setup_cleanup.sh
#!/bin/bash

# === 1. 環境變數設定 ===
SCRIPT_PATH="/opt/cron-scripts/clean_images.sh"
TARGET_DIR="/data01/comfyui_data"
LOG_FILE="/opt/cron-scripts/clean_images.log"
CRON_TIME="0 3 * * *"

echo "正在開始安裝 comfyui 清理腳本..."

# === 2. 建立必要資料夾與日誌檔 ===
sudo mkdir -p /opt/cron-scripts
sudo touch $LOG_FILE
sudo chmod 666 $LOG_FILE

# === 3. 寫入清理腳本內容 ===
cat << 'EOF2' | sudo tee $SCRIPT_PATH > /dev/null
#!/bin/bash
# 目標路徑與日誌設定
TARGET_DIR="/data01/comfyui_data"
LOG_FILE="/opt/cron-scripts/clean_images.log"

if [ ! -d "$TARGET_DIR" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 錯誤: 目錄 $TARGET_DIR 不存在。" >> $LOG_FILE
    exit 1
fi

cd "$TARGET_DIR"
echo "$(date '+%Y-%m-%d %H:%M:%S') - 開始清理 7 天前檔案..." >> $LOG_FILE

# 分批處理 instance* 資料夾避免 Argument list too long
find . -maxdepth 1 -name "instance*" -type d | while read dir; do
    find "$dir" -type f -regextype posix-extended \
    -iregex ".*\.(jpeg|jpg|png|webp|bmp|gif|mpo|mp4|mov|arw|cr2|heic|heif|avif)" \
    -mtime +7 -delete
done

echo "$(date '+%Y-%m-%d %H:%M:%S') - 清理完成。" >> $LOG_FILE
echo "-------------------------------------------" >> $LOG_FILE
EOF2

# 設定執行權限
sudo chmod +x $SCRIPT_PATH

# === 4. 設定 Cronjob (核心自動化邏輯) ===
# 檢查是否已經存在相同的排程，避免重複寫入
(sudo crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "$CRON_TIME $SCRIPT_PATH") | sudo crontab -

echo "=========================================="
echo "安裝成功！"
echo "1. 腳本路徑: $SCRIPT_PATH"
echo "2. 日誌檔案: $LOG_FILE"
echo "3. 排程時間: 每天凌晨 03:00"
echo "您可以輸入 'sudo crontab -l' 來確認排程。"
echo "=========================================="
EOF

chmod +x /tmp/setup_cleanup.sh
bash /tmp/setup_cleanup.sh
