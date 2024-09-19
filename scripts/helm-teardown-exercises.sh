#!/bin/bash

# extract the current directory name from pwd command (everything behind the last backslash
CURRENT_DIR=$(pwd | sed 's:.*/::')
if [ "$CURRENT_DIR" != "scripts" ]
then
  echo "please change directory to scripts folder and execute the shell script again."
  exit 1
fi

read -p "keep ingress nginx to retain same nodebalancer dns name? (y/n) " RETAIN_INGRESS

cd ..

export KUBECONFIG=test-cluster-kubeconfig.yaml
# keep to retain nodebalancer dns name
if [ $RETAIN_INGRESS = "y" ]
then
  echo "retaining ingress-nginx"
else
  echo "uninstalling ingress-nginx"
  helm uninstall nginx-ingress --namespace exercises
fi

helm uninstall java-mysql-phpmyadmin
kubectl delete pvc data-mysql-0 data-mysql-1 data-mysql-2 -n exercises
kubectl delete secret java-app-mysql-env -n exercises
kubectl delete secret aws-ecr-config -n exercises

sleep 2
kubectl get all -n exercises

# kubectl delete -f k8s/exercises/01-mysql-statefulset.yaml
# kubectl delete -f k8s/exercises/01-mysql-service.yaml
# kubectl delete -f k8s/exercises/01-mysql-configmap.yaml
# kubectl delete -f k8s/exercises/01-java-app-deployment.yaml
# kubectl delete -f k8s/exercises/01-phpmyadmin-deployment.yaml
# kubectl delete -f k8s/exercises/01-phpmyadmin-configmap.yaml
# kubectl delete -f k8s/exercises/01-ingress-configuration.yaml