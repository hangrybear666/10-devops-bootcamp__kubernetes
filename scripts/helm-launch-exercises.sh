#!/bin/bash

# extract the current directory name from pwd command (everything behind the last backslash
CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != "scripts" ]
then
  echo "please change directory to scripts folder and execute the shell script again."
  exit 1
fi

read -p "Please provide your AWS ECR URL (like so: 010928217051.dkr.ecr.eu-central-1.amazonaws.com): " AWS_ECR_URL
read -p "Please provide your AWS ECR repo name (like so: k8s-imgs): " AWS_ECR_REPO_NAME
read -p "Please provide your NodeBalancer Public DNS Name (like so: 143-42-222-246.ip.linodeusercontent.com): " NODEBALANCER_PUBLIC_DNS
read -p "Please provide your java-app version tag (like so: 2.3): " JAVA_APP_VERSION

cd ..
# docker login to ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin $AWS_ECR_URL
cp /home/$USER/.docker/config.json config/

# create secrets
export KUBECONFIG=test-cluster-kubeconfig.yaml
kubectl create namespace exercises
kubectl create secret generic aws-ecr-config \
  --from-file=.dockerconfigjson=config/config.json \
  --type=kubernetes.io/dockerconfigjson \
  --namespace exercises
kubectl create secret generic java-app-mysql-env \
  --from-env-file=java-app/.env \
  --namespace exercises
echo "-----" && echo "created aws-ecr-config & java-app-mysql-env secrets" && echo "-----"

# install nginx ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --version 4.11.2 --namespace exercises
echo "-----" && echo "installed nginx ingress" && echo "-----"

# replace HOST in index.html with NodeBalancer IP
sed -i "s/const HOST = \"my-java-app.com\";/const HOST = \"$NODEBALANCER_PUBLIC_DNS\";/" java-app/src/main/resources/static/index.html
echo "-----" && echo "replaced HOST in java-app/src/main/resources/static/index.html" && echo "-----"

# build docker image
docker build -t java-app:$JAVA_APP_VERSION java-app/.
docker tag java-app:$JAVA_APP_VERSION $AWS_ECR_URL/$AWS_ECR_REPO_NAME:java-app-$JAVA_APP_VERSION
docker push $AWS_ECR_URL/$AWS_ECR_REPO_NAME:java-app-$JAVA_APP_VERSION
echo "-----" && echo "built and pushed $AWS_ECR_URL/$AWS_ECR_REPO_NAME:java-app-$JAVA_APP_VERSION" && echo "-----"

helm install java-mysql-phpmyadmin helm/java-mysql-phpmyadmin \
  -f helm/java-mysql-phpmyadmin/values/value-override-java-mysql-phpmyadmin.yaml \
  --set nodeBalancerPublicDns=$NODEBALANCER_PUBLIC_DNS \
  --set ecrImageRepository=$AWS_ECR_URL \
  --set ecrImageName=$AWS_ECR_REPO_NAME \
  --set javaImageTag=java-app-$JAVA_APP_VERSION \
  --debug

