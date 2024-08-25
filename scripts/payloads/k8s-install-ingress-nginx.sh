#!/bin/bash -i
# -i flag for bash file is necessary to start shell in interactive mode, making exposed aliases available. 
# kubectl is an alias for "minikube kubectl" saved in ~/.bashrc

# enable ingress addon
minikube addons enable ingress

# delete prior deployments
kubectl delete service web
kubectl delete deployment web
kubectl delete service web2
kubectl delete deployment web2
kubectl delete -f nginx-test-ingress.yaml 

# create web app deployments
kubectl create deployment web --image=gcr.io/google-samples/hello-app:1.0
kubectl create deployment web2 --image=gcr.io/google-samples/hello-app:2.0

# expose the web apps on port 8080 internally
kubectl expose deployment web --type=NodePort --port=8080
kubectl expose deployment web2 --type=NodePort --port=8080 

# start the controller
kubectl apply -f nginx-test-ingress.yaml

# set a static http and https ip for the controller
kubectl patch svc ingress-nginx-controller -n ingress-nginx -p '{
  "spec": {
    "ports": [
      {
        "port": 80,
        "nodePort": 30080,
        "protocol": "TCP",
        "name": "http"
      },
      {
        "port": 443,
        "nodePort": 30443,
        "protocol": "TCP",
        "name": "https"
      }
    ]
  }
}'
# sleep while services startup
sleep 8

# test the connection internally
SERVICE_URL=$(minikube service web --url)
curl $SERVICE_URL
curl --resolve "$REMOTE_ADDRESS:80:$( minikube ip )" -i http://$REMOTE_ADDRESS
curl --resolve "$REMOTE_ADDRESS:80:$( minikube ip )" -i http://$REMOTE_ADDRESS/v2
# curl --resolve "64.226.117.247:80:192.168.49.2" -i http://64.226.117.247

echo "---------------------------------------------------
MINIKUBE INGRESS-CONTROLLER SERVICE:"
minikube service ingress-nginx-controller -n ingress-nginx

echo "---------------------------------------------------
TO TEST THE CONNECTION FROM OUTSIDE USE
curl -i http://$REMOTE_ADDRESS:30080"

echo "---------------------------------------------------
MINIKUBE IP IS:
$( minikube ip )"