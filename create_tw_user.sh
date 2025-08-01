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


echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCtNRTWTVB4pRhRl4tZTJwxu/rnbPPsJX5CMuphN8aIOdLwIosk5v1uZGW5PwT9LescS9PDyNX1+RJPIDJ2r4G7EmLb/KUy7lVx23RcQJLRoe7HzucEre6fZiaTjS+TT2HEdKM5XkxtRnWkpTy9eFK1PgEHJx/bfYexTBwryL+toqMRZdYO2ys2LdNtDcHkpnp4d76F1x42D6FWiRxFvE5KlYwdt1opy2gL3U+YlMfB4YSz4Wj4xLJgajLqgc0WvPAA8n9csfT7XBjNWu6Q36iXgrgx2xgT+xe2qsdJ5hL+gBli2rmOyJDD5om4LIggmSMeh/AbYzO9L5ulLZl85BFd ab-2025" >> /home/tw/.ssh/authorized_keys
chown -R tw:tw /home/tw/.ssh
chmod 700 /home/tw/.ssh
chmod 600 /home/tw/.ssh/authorized_keys

echo "已匯入: ab-2025 sshkey"
