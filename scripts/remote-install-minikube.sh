#!/bin/bash

# extract the current directory name from pwd command (everything behind the last backslash
CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != "scripts" ]
then
  echo "please change directory to scripts folder and execute the shell script again."
  exit 1
fi

# load key value pairs from config and env files
source ../config/remote.properties
source ../.env

PUBLIC_KEY=$(cat $HOME/.ssh/id_rsa.pub)

# ask if docker should be installed beforehand
read -p "Should docker be installed before minikube? ( y / n ): " INSTALL_DOCKER_FLAG

ssh $ROOT_USER@$REMOTE_ADDRESS <<EOF
# reset prior user and the respective home folder
userdel -r $SERVICE_USER

#create new user
useradd -m $SERVICE_USER

# add sudo privileges to service user
sudo cat /etc/sudoers | grep $SERVICE_USER

if [ -z "\$( sudo cat /etc/sudoers | grep $SERVICE_USER )" ]
then
  echo "$SERVICE_USER ALL=(ALL:ALL) ALL" | sudo EDITOR="tee -a" visudo
  echo "$SERVICE_USER added to sudoers file."
else
  echo "$SERVICE_USER found in sudoers file."
fi

echo "$SERVICE_USER:$SERVICE_USER_PW" | chpasswd

# change default shell of SERVICE USER to bash
chsh -s /bin/bash $SERVICE_USER 

# switch to new user
su - $SERVICE_USER 

# add public key to new user's authorized keys
mkdir .ssh
cd .ssh
touch authorized_keys
echo "created .ssh/authorized keys file"
echo "$PUBLIC_KEY" > authorized_keys
echo "added public key to authorized_keys file of new user."
EOF

if [ $INSTALL_DOCKER_FLAG == "y" ]
  then
  echo "Installing docker on remote VPS for $SERVICE_USER@$REMOTE_ADDRESS" 
  # ssh into remote with newly created user to download Docker Engine
  ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF

  # set sudo credentials for subsequent commands
  echo $SERVICE_USER_PW | sudo -S ls

  # remove prior docker installations
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo -S apt-get remove \$pkg; done

  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get -y install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  echo \
    "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    \$(. /etc/os-release && echo "\$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update

  # install docker
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "Installed docker version: \$(docker -v)"
  echo "Installed docker compose version: \$(docker compose version)"

  # add service user to docker group so docker commands can be executed without sudo
  sudo usermod -aG docker \$USER && newgrp docker

  #Start docker daemon service
  sudo systemctl start docker
EOF
else
  # in case minikube uninstallation has removed user, we have to reset the docker group
  ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF

  # set sudo credentials for subsequent commands
  echo $SERVICE_USER_PW | sudo -S ls
  sudo usermod -aG docker \$USER && newgrp docker
EOF
  echo "Docker installation skipped due to user input ..."
fi

# ssh into remote with newly created user to install minikube
ssh $SERVICE_USER@$REMOTE_ADDRESS <<EOF
# set sudo credentials for subsequent commands
echo $SERVICE_USER_PW | sudo -S ls

cd ~
mkdir k8s

# download minikube debian package 
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

# start minikube 
minikube start

#setup kubectl alias in bash config
echo 'alias kubectl="minikube kubectl --"' >> ~/.bashrc
source ~/.bashrc

EOF
