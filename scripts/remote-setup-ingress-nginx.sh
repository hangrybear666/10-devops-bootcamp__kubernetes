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

# copy payload to remote
scp payloads/k8s-install-ingress-nginx.sh $SERVICE_USER@$REMOTE_ADDRESS:~/k8s/k8s-install-ingress-nginx.sh
scp payloads/nginx-test-ingress.yaml $SERVICE_USER@$REMOTE_ADDRESS:~/k8s/nginx-test-ingress.yaml

# execute payload on remote
ssh -t $SERVICE_USER@$REMOTE_ADDRESS <<EOF
cd ~/k8s
export SERVICE_USER_PW=$SERVICE_USER_PW
export REMOTE_ADDRESS=$REMOTE_ADDRESS
./k8s-install-ingress-nginx.sh
EOF
