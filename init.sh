echo -e "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ jammy nginx\ndeb-src http://nginx.org/packages/mainline/ubuntu/ jammy nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
wget http://nginx.org/keys/nginx_signing.key
sudo apt-key add nginx_signing.key
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt-get update
sudo apt-get install -y python3.9
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1
sudo update-alternatives --config python3
sudo apt-get remove -y python3-apt
sudo apt-get install -y python3-apt
sudo apt-get remove -y python3-distutils
sudo apt-get install -y python3-distutils
curl -O https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py

sudo apt-get install -y python3.9-dev python3-pip python3-cffi python3.9-venv gcc libpq-dev libpcre3 libpcre3-dev
sudo apt-get install -y build-essential
sudo apt-get install -y libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 libffi-dev shared-mime-info
sudo apt-get install -y nginx nodejs postgresql postgresql-contrib
sudo apt-get update && sudo apt-get dist-upgrade -y