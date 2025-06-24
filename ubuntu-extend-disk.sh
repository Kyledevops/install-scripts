#!/bin/bash

# 檢查是否以 root 權限執行
if [ "$EUID" -ne 0 ]; then
  echo "請以 root 權限執行此腳本"
  exit 1
fi

# 定義變數
VG_NAME="ubuntu-vg"
LV_NAME="ubuntu-lv"
LV_PATH="/dev/${VG_NAME}/${LV_NAME}"  # 使用 /dev/ubuntu-vg/ubuntu-lv 格式

# 步驟 1：檢查卷組可用空間
echo "檢查卷組可用空間..."
vgdisplay ${VG_NAME}
FREE_SPACE=$(vgdisplay ${VG_NAME} | grep "Free  PE / Size" | awk '{print $6}')
echo "卷組可用空間: ${FREE_SPACE}"

# 步驟 2：擴展邏輯卷到最大可用空間
echo "正在擴展邏輯卷到最大可用空間..."
lvextend -l +100%FREE ${LV_PATH}
if [ $? -ne 0 ]; then
  echo "擴展邏輯卷失敗，請檢查錯誤訊息"
  exit 1
fi

# 步驟 3：調整文件系統大小
echo "正在調整文件系統大小..."
resize2fs ${LV_PATH}
if [ $? -ne 0 ]; then
  echo "調整文件系統失敗，請檢查錯誤"
  exit 1
fi

# 步驟 4：驗證結果
echo "擴展完成，當前磁碟使用情況："
df -h /

echo "操作完成！"