#!/bin/bash

# 取得系統版本
OS_VERSION=$(grep -oP '(?<=^VERSION_ID=")[^"]+' /etc/os-release 2>/dev/null)

# 判斷 Amazon Linux 版本
if [[ -f /etc/os-release && $(grep -i "amazon linux" /etc/os-release) ]]; then
    if [[ "$OS_VERSION" == "2" ]]; then
        echo "Detected Amazon Linux 2"
        amazon-linux-extras enable docker
        amazon-linux-extras install docker -y
        systemctl start docker
        systemctl enable docker
    elif [[ "$OS_VERSION" == "2023" ]]; then
        echo "Detected Amazon Linux 2023"
        yum install -y docker
        service docker start
    else
        echo "Unknown Amazon Linux version: $OS_VERSION"
        exit 1
    fi
else
    echo "Not Amazon Linux. Using get.docker.com script to install Docker..."
    curl -fsSL https://get.docker.com | sh
fi

# 確保 docker 服務啟動
systemctl enable docker
systemctl start docker

# 加入 ec2-user 或當前用戶到 docker 群組
if id "ec2-user" &>/dev/null; then
    usermod -aG docker ec2-user
    echo "Added ec2-user to the docker group"
else
    usermod -aG docker $(whoami)
    echo "Added $(whoami) to the docker group"
fi

# 安裝 Docker Compose
echo "Installing Docker Compose..."
wget -q https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/bin/docker-compose 
chmod +x /usr/bin/docker-compose

# 驗證安裝
docker --version
docker-compose --version

echo "Docker and Docker Compose installation completed successfully!"