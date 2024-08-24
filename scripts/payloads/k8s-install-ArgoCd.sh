#!/bin/bash -i
# -i flag for bash file is necessary to start shell in interactive mode, making exposed aliases available. 
# kubectl is an alias for "minikube kubectl" saved in ~/.bashrc

# install ArgoCD in your kubernetes cluster
echo "Installing ArgoCD GitOps tool within your k8s cluster"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# install ArgoCD CLI
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
echo "Installing ArgoCD CLI latest stable release $VERSION"
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
echo "$SERVICE_USER_PW" | sudo -S install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

# save default admin credentials for login
ADMIN_USERNAME=admin
INITIAL_ADMIN_PW=$(argocd admin initial-password -n argocd | head -n 1)
INITIAL_ADMIN_PW_ALTERNATIVE=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# change argocd-server service to type LoadBalancer in order to expose the API as an external service
echo "
Exposing argocd-server API as external service..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# get ip address of argocd-server
ARGOCD_IP_ADDRESS=$(minikube service argocd-server -n argocd --url | head -n 1 | awk -F 'http://' '{print $2}')

# login to argocd-server for the first time
argocd login --username $ADMIN_USERNAME --password $INITIAL_ADMIN_PW --insecure $ARGOCD_IP_ADDRESS
# change the default password to the one provided in your .env file
argocd account update-password --account $ADMIN_USERNAME --current-password $INITIAL_ADMIN_PW --new-password $ARGOCD_ADMIN_PW

# optional, since argocd runs in same cluster as our apps, the default is sufficient
#argocd cluster add --yes minikube


# to start a demo app with argo cli
#kubectl config set-context --current --namespace=argocd
#argocd app create guestbook --repo https://github.com/argoproj/argocd-example-apps.git --path guestbook --dest-server https://kubernetes.default.svc --dest-namespace default
#argocd app sync guestbook

# view status
#argocd app get guestbook



