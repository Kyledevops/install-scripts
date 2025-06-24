#!/bin/bash

# 使用者名稱
USERNAME="tw"

# 產生隨機密碼（12 字元：含大小寫與數字）
PASSWORD=$(< /dev/urandom tr -dc A-Za-z0-9 | head -c12)

# 建立使用者並建立 home 目錄
useradd -m -s /bin/bash "$USERNAME"

# 設定密碼
echo "${USERNAME}:${PASSWORD}" | chpasswd

# 加入 sudo 群組
usermod -aG sudo "$USERNAME"

# 設定免密 sudo
echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/"$USERNAME"
chmod 440 /etc/sudoers.d/"$USERNAME"

# 顯示帳號資訊
echo "✅ 使用者已建立"
echo "使用者名稱: $USERNAME"
echo "密碼: $PASSWORD"