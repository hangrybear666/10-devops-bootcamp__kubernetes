#!/bin/bash -i
# -i flag for bash file is necessary to start shell in interactive mode, making exposed aliases available. 
# kubectl is an alias for "minikube kubectl" saved in ~/.bashrc

# 
minikube addons enable ingress

# delete prior deployments
kubectl delete service web
kubectl delete deployment web
kubectl delete service web2
kubectl delete deployment web2
kubectl delete -f nginx-test-ingress.yaml 

kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
kubectl create deployment web2 --image=gcr.io/google-samples/hello-app:2.0

kubectl expose deployment web --type=NodePort --port=8080
kubectl expose deployment web2 --port=8080 --type=NodePort

kubectl apply -f nginx-test-ingress.yaml

#kubectl get ingress
sleep 8
SERVICE_URL=$(minikube service web --url)
curl $SERVICE_URL
curl --resolve "$REMOTE_ADDRESS:80:$( minikube ip )" -i http://$REMOTE_ADDRESS
curl --resolve "$REMOTE_ADDRESS:80:$( minikube ip )" -i http://$REMOTE_ADDRESS/v2

#curl --resolve "$REMOTE_ADDRESS:80:192.168.49.2" -i http://$REMOTE_ADDRESS