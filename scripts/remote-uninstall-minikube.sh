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
read -p "Should docker be uniinstalled as well? ( y / n ): " UNINSTALL_DOCKER_FLAG

ssh $ROOT_USER@$REMOTE_ADDRESS <<EOF

# remove minikube
minikube stop 
minikube delete --all --purge
dpkg --remove minikube


# reset prior user and the respective home folder
userdel -r $SERVICE_USER

if [ $UNINSTALL_DOCKER_FLAG == "y" ]
then
  # remove prior docker installations
  sudo apt-get update
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd docker-ce docker-ce-cli \
    containerd.io docker-buildx-plugin docker-compose-plugin runc; \
    do sudo -S apt-get remove \$pkg; done
  sudo apt -y autoremove
fi

EOF
