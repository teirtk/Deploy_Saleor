#!/bin/bash
echo -e "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ jammy nginx\ndeb-src http://nginx.org/packages/mainline/ubuntu/ jammy nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
wget --quiet -O - http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql-pgdg.list > /dev/null
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.18_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.18_amd64.deb
sudo apt-get update && sudo apt-get dist-upgrade -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
 "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
 sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update && sudo apt-get install -y python3.9 python3.9-dev python3.9-venv gcc libpq-dev libcairo2 libgdk-pixbuf2.0-0 liblcms2-2 libopenjp2-7 libpango-1.0-0 libpangocairo-1.0-0 libtiff5 libwebp6 libxml2 libpq5 shared-mime-info mime-support nginx nodejs postgresql-14 docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
echo 'image/webp webp' >> /etc/mime.types
echo 'image/avif avif' >> /etc/mime.types
usermod -aG docker kiet
newgrp docker
source $HD/Deploy_Saleor/deploy.sh