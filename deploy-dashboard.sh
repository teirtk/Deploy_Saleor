#!/bin/bash
sudo -u $UN git clone https://github.com/saleor/saleor-dashboard.git
wait
cd saleor-dashboard
docker run --rm -it $(docker build -q .)
