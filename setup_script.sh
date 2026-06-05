#!/bin/bash
set -e
sudo apt update && sudo apt upgrade -y
sudo apt install -y ufw fail2ban nginx postgresql python3-pip git curl
sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 5000/tcp && sudo ufw allow 8080/tcp && sudo ufw --force enable
sudo systemctl enable fail2ban && sudo systemctl start fail2ban
sudo sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
echo "PubkeyAuthentication yes" | sudo tee -a /etc/ssh/sshd_config && sudo systemctl restart sshd
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo EXTERNAL_URL="http://$(curl -s ifconfig.me)" apt install -y gitlab-ce
sudo apt install -y python3-flask
sudo mkdir -p /var/www/myapp && sudo cp app.py /var/www/myapp/ && cd /var/www/myapp && sudo nohup python3 app.py > /tmp/app.log 2>&1 &
echo "Setup Complete"
