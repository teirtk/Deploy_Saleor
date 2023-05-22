echo -e "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ focal nginx\ndeb-src http://nginx.org/packages/mainline/ubuntu/ focal nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list
wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo apt-get update && sudo apt-get dist-upgrade -y && sudo apt-get install libssl1.1
sudo apt-get install -y python3-dev python3-pip python3-cffi python3-venv gcc libpq-dev libpcre3 libpcre3-dev build-essential libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info nginx nodejs postgresql postgresql-contrib