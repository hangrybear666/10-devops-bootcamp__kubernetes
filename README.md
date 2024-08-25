# DESCRIPTION HEADER

DESCRIPTION DETAIL

The main projects are:
- An ArgoCD deployment in Kubernetes following GitOps principles for declarative configuration versioning and storage.

## Setup

1. Pull SCM

    Pull the repository locally by running
    ```
    git clone https://github.com/hangrybear666/10-devops-bootcamp__kubernetes.git
    ```
2. Install Minikube on your local OS (or in our case a remote VPS)

    For local development simply follow https://minikube.sigs.k8s.io/docs/start/. 
    
    The following steps execute automatic installation on remote debian based VPS:

    a. Add `SERVICE_USER_PW=xxx` to your `.env` file so the installation script can add this to the new user. Overwrite`REMOTE_ADDRESS=xxx` to yours in `config/remote.properties`

    b. Run the installation script in `scripts/` folder and type `y` if you wish to install docker before installaing minikube and `n` if docker is already installed.
    ```
    # this is aimed at Debian-like distros with the apt package manager
    ./remote-install-minikube.sh
    # If you want to remove docker and/or minikube run
    ./remote-uninstall-minikube.sh
    ``` 

3. Install additional dependencies 

    Install `jq` to parse json files. 


## Usage (Demo Projects)

1. Deploy a simple application with ConfigMap, (unencrypted/insecure) Secret and Service in k8s cluster

    ```
    # SETUP
    kubectl apply -f k8s/mongo-secret.yaml
    kubectl apply -f k8s/mongodb.yaml
    kubectl apply -f k8s/mongo-configmap.yaml
    kubectl apply -f k8s/mongo-express.yaml
    # access minicube-ip:30000 in the browser or run
    minikube service mongo-express-service
    #default credentials for mongo-express are admin:pass
    
    # INFO
    MONGO_POD=$(kubectl get pods --no-headers | grep "mongodb-deployment" | awk '{print $1}')
    EXPRESS_POD=$(kubectl get pods --no-headers | grep "mongo-express" | awk '{print $1}')
    kubectl describe pod $MONGO_POD
    kubectl logs $EXPRESS_POD
    kubectl describe service mongodb-service
    kubectl get all | grep mongo


    ```


## Usage (Exercises)

TODO

## Usage (Bonus Setup)

1. First of all, we want to setup ArgoCD to use GitOps principles for writing declarative configuration, versioning, storing and running our k8s cluster 

    See https://argo-cd.readthedocs.io/en/stable/getting_started/

    a. Add `ARGOCD_ADMIN_PW=xxx` to `.env` file

    b. Navigate to `scripts/` folder and execute the installation script.
    ```
    ./remote-setup-ArgoCD.sh
    ```

2. We also want to setup ingress-nginx for minikube to handle incoming traffic from the outside world

    See https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

    a. Navigate to `scripts/` folder and execute the installation script.
    ```
    ./remote-setup-ingress-nginx.sh
    ```

    b. Install nginx reverse proxy to forward outside requests to the VPS to the minikube ip address on the ingress controller port. To configure nginx replace `proxy_pass` ip with your minikube ip from the output of step a)
    ```
    ssh root@<REMOTE_ADDRESS>
    sudo apt update
    sudo apt install nginx-full

    echo "
    stream {
        server {
            listen 30080;
            proxy_pass 192.168.49.2:80;
        }
        
        server {
            listen 30443;
            proxy_pass 192.168.49.2:443;
        }
    }
    " >> /etc/nginx/nginx.conf
    
    sudo nginx -t
    
    sudo systemctl restart nginx
    ```
    Now you can access <REMOTE_ADDRESS>:30080 in a browser from any external device!

    c. Currently only http access on port 30080 is supported. HTTPS certificate config is a topic for another day. See potentially https://www.zepworks.com/posts/access-minikube-remotely-kvm/#4-certs or https://minikube.sigs.k8s.io/docs/handbook/untrusted_certs/ 
    