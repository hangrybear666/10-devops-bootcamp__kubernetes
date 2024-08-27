# DESCRIPTION HEADER

DESCRIPTION DETAIL

The main projects are:
- A simple app with ConfigMap, (unencrypted/insecure) Secret and Service in k8s cluster
- A simple app with ConfigMap File and Secret File Volume Mounting for initializing containers with custom files

The bonus projects are:
- An ArgoCD deployment in Kubernetes following GitOps principles for declarative configuration versioning and storage.
- An nginx reverse proxy to route external traffic into a remote linux VPS to an ingress-nginx-controller which forwards the requests to an internal service

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

4. Install helm on your local OS

    See https://helm.sh/docs/intro/install/
    ```
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ```


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

2. Deploy ConfigMap File and Secret File Volume Mounting for initializing containers with custom files

    a. To start a basic mosquitto container with default values and log the configuration file, run:
    ```
    # basic mosquitto app with standard conf
    kubectl apply -f k8s/mosquitto-without-volumes.yaml  

    # log default config
    MOSQUITTO_POD=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "mosquitto")
    kubectl exec $MOSQUITTO_POD -- cat /mosquitto/config/mosquitto.conf
    ```

    b. To overwrite the mosquitto.conf file and create a secret.file in the containers via Volume mounts, run:
    ```
    kubectl apply -f k8s/mosquitto-config-file.yaml
    kubectl apply -f k8s/mosquitto-secret-file.yaml
    kubectl apply -f k8s/mosquitto.yaml
    # log both conf and secret file from volume mount to console
    MOSQUITTO_POD=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "mosquitto")
    kubectl exec $MOSQUITTO_POD -- sh -c \
      "echo -e '\nmosquitto.conf:' \
      && cat /mosquitto/config/mosquitto.conf \
      && echo -e '\nsecret.file:' \
      && cat /mosquitto/secret/secret.file"
    ```

3. Start a Managed k8s cluster on Linode and run a replicated StatefulSet application with multiple nodes and attached volumes using Helm Charts

    a. Create an Account on the Linode Cloud and then Create a Kubernetes Cluster https://cloud.linode.com/kubernetes/clusters named `test-cluster` in your Region without High Availability (HA) Control Plane to save costs. Adding 3 Nodes with 2GB each on a shared CPU is sufficient. 

    b. Once the cluster is running, download `test-cluster-kubeconfig.yaml`. If your file is named differently, add it to `.gitignore` as it contains sensitive data. Then uninstall minikube and install kubectl manually, otherwise kubectl will be used with the minikube binary resulting in connection errors. 

    Installation help: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
    ```
    minikube stop 
    minikube delete --all --purge
    # delete alias kubectl="minikube kubectl -- from .bashrc
    vim ~/.bashrc
    # e.g. remove from ubuntu
    sudo rm /usr/local/bin/minikube
    # or remove from debian
    dpkg --remove minikube

    # install kubectl 
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

    # change permissions for downloaded kubeconfig
    chmod 400 test-cluster-kubeconfig.yaml
    export KUBECONFIG=test-cluster-kubeconfig.yaml
    kubectl get nodes
    ```

    c. Add the helm repo and install a mongodb helm chart. For reference see https://artifacthub.io/packages/helm/bitnami/mongodb
    ```
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm search repo bitnami/mongodb
    helm install mongodb --values k8s/helm-mongodb.yaml bitnami/mongodb --version 15.6.21
    # username is admin
    # for password run
    kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d
    ```

    d. Add a mongo-express container and service listening on port 8081 internally for incoming traffic to render a GUI in browser.
    ```
    kubectl apply -f k8s/helm-mongo-express.yaml
    ```

    e. Add nginx-ingress-controller to route incoming traffic from Linode's NodeBalancer to the mongo-express internal ClusterIP Service. Installation of the Helm chart also automatically sets up a NodeBalancer on Linode, the public dns name of which we have to save and replace in `k8s/helm-ingress.yaml` in the `- host: ` value
    ```
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm install nginx-ingress ingress-nginx/ingress-nginx --version 4.11.2 --set controller.publishService.enabled=true
    # add Linode NodeBalancer hostname to k8s/helm-ingress.yaml 
    kubectl apply -f k8s/helm-ingress.yaml
    ```

    f. Navigate to your Nodebalancer DNS host name to access mongo-express with default credentials `admin` and `pass` to persist data. You can uninstall the database by running `helm uninstall mongodb` then start it back up with the command from step c) and see that data has been persisted in the persistent volume on Linode which are subsequently reattached to their respective pods.


## Usage (Exercises)

TODO

## Usage (Bonus Remote VPS Setup)

1. First of all, we want to setup ArgoCD to use GitOps principles for writing declarative configuration, versioning, storing and running our k8s cluster 

    See https://argo-cd.readthedocs.io/en/stable/getting_started/

    a. Add `ARGOCD_ADMIN_PW=xxx` to `.env` file

    b. Navigate to `scripts/` folder and execute the installation script.
    ```
    ./remote-setup-ArgoCD.sh
    ```

2. We also want to setup ingress-nginx for minikube to handle incoming traffic from the outside world into our remote VPS

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
    You can access the plain site http://<REMOTE_ADDRESS>:30080 in a browser from any external device.
    You can access the TLS site https://<REMOTE_ADDRESS>:30443 in a browser from any external device.
    NOTE: HTTPS certificate config to remove security warning is a topic for another day. See potentially https://www.zepworks.com/posts/access-minikube-remotely-kvm/#4-certs or https://minikube.sigs.k8s.io/docs/handbook/untrusted_certs/ 
    
