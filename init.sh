echo -e "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ jammy nginx\ndeb-src http://nginx.org/packages/mainline/ubuntu/ jammy nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
wget --quiet -O - http://nginx.org/keys/nginx_signing.key | sudo apt-key add -
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql-pgdg.list > /dev/null
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.18_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.18_amd64.deb
sudo apt-get update && sudo apt-get dist-upgrade -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
 sudo apt-get update && sudo apt-get install -y python3.9 python3.9-dev python3-cffi python3.9-venv gcc libpq-dev libpcre3 libpcre3-dev build-essential libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info nginx nodejs postgresql-14