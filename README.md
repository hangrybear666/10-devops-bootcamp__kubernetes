# DESCRIPTION HEADER

DESCRIPTION DETAIL

The main projects are:
- A simple app with ConfigMap, locally generated Secret to avoid SCM exposure and external LoadBalancer Service in k8s cluster
- A simple app with ConfigMap File and Secret File Volume Mounting for initializing containers with custom files
- Managed k8s cluster on Linode running a replicated StatefulSet application with multiple nodes and attached persistent storage volumes using Helm Charts
- Deployment of a custom NodeJS-application image published and pulled from AWS ECR, with mongodb and mongo-express pods & services running

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
    ```bash
    # this is aimed at Debian-like distros with the apt package manager
    ./remote-install-minikube.sh
    # If you want to remove docker and/or minikube run
    ./remote-uninstall-minikube.sh
    ``` 

3. Install additional dependencies 

    Install `jq` to parse json files. 

4. Install helm on your local OS

    See https://helm.sh/docs/intro/install/
    ```bash
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ```


## Usage (Demo Projects)

### 1. Deploy a simple application with ConfigMap, locally generated Secret to avoid SCM exposure and external LoadBalancer Service in k8s cluster

NOTE: Replace `mongo-root-username` and `mongo-root-password` values with your own.
```bash
kubectl create secret generic mongodb-secret \
    --namespace=default \
    --from-literal=mongo-root-username='admin' \
    --from-literal=mongo-root-password='password'
kubectl apply -f k8s/mongodb.yaml
kubectl apply -f k8s/mongo-configmap.yaml
kubectl apply -f k8s/mongo-express.yaml
# access minicube-ip:30000 in the browser or run
minikube service mongo-express-service
#default credentials for mongo-express are admin:pass
```

<details closed>
<summary><b>Click for informative kubectl commands</b></summary>

```bash
MONGO_POD=$(kubectl get pods --no-headers | grep "mongodb-deployment" | awk '{print $1}')
EXPRESS_POD=$(kubectl get pods --no-headers | grep "mongo-express" | awk '{print $1}')
kubectl describe pod $MONGO_POD
kubectl logs $EXPRESS_POD
kubectl describe service mongodb-service
kubectl get all | grep mongo
```
</details>

### 2. Deploy ConfigMap File and Secret File Volume Mounting for initializing containers with custom files

a. To start a basic mosquitto container with default values and log the configuration file, run:
```bash
# basic mosquitto app with standard conf
kubectl apply -f k8s/mosquitto-without-volumes.yaml  

# log default config
MOSQUITTO_POD=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "mosquitto")
kubectl exec $MOSQUITTO_POD -- cat /mosquitto/config/mosquitto.conf
```

b. To overwrite the mosquitto.conf file and create a secret.file in the containers via Volume mounts, run:

NOTE: replace `-from-literal=secret.file='Password123!'` with your desired password
```bash
kubectl apply -f k8s/mosquitto-config-file.yaml
kubectl create secret generic mosquitto-secret-file \
    --from-literal=secret.file='Password123!' \
    --type=Opaque
kubectl apply -f k8s/mosquitto.yaml

# log both conf and secret file from volume mount to console
MOSQUITTO_POD=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "mosquitto")
kubectl exec $MOSQUITTO_POD -- sh -c \
    "echo -e '\nmosquitto.conf:' \
    && cat /mosquitto/config/mosquitto.conf \
    && echo -e '\nsecret.file:' \
    && cat /mosquitto/secret/secret.file"
```

### 3. Start a Managed k8s cluster on Linode and run a replicated StatefulSet application with multiple nodes and attached persistent storage volumes using Helm Charts

a. Create an Account on the Linode Cloud and then Create a Kubernetes Cluster https://cloud.linode.com/kubernetes/clusters named `test-cluster` in your Region without High Availability (HA) Control Plane to save costs. Adding 3 Nodes with 2GB each on a shared CPU is sufficient. 

b. Once the cluster is running, download `test-cluster-kubeconfig.yaml`. If your file is named differently, add it to `.gitignore` as it contains sensitive data. Then uninstall minikube and install kubectl manually, otherwise kubectl will be used with the minikube binary resulting in connection errors. 

<details closed>
<summary><b>Click for installation instructions</b></summary>

Installation help: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
```bash
minikube stop 
minikube delete --all --purge
# delete alias kubectl="minikube kubectl --" from .bashrc
vim ~/.bashrc
# e.g. remove from ubuntu
sudo rm /usr/local/bin/minikube
# or remove from debian
dpkg --remove minikube

# install kubectl 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```
</details>

Then run:
```bash
# change permissions for downloaded kubeconfig
chmod 400 test-cluster-kubeconfig.yaml
export KUBECONFIG=test-cluster-kubeconfig.yaml
kubectl get nodes
```

c. Add the helm repo and install a mongodb helm chart. Then connect to the db with a temporary mongo client to test the connection. For reference see https://artifacthub.io/packages/helm/bitnami/mongodb
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo bitnami/mongodb
helm install mongodb --values k8s/helm-mongodb.yaml bitnami/mongodb --version 13.16.3
# username is root - for password run:
export MONGODB_ROOT_PASSWORD=$(kubectl get secret --namespace default mongodb -o jsonpath="{.data.mongodb-root-password}" | base64 -d)
# create mongo client
kubectl run --namespace default mongodb-client --rm --tty -i --restart='Never' --env="MONGODB_ROOT_PASSWORD=$MONGODB_ROOT_PASSWORD" --image docker.io/bitnami/mongodb:6.0.8-debian-11-r12 --command -- bash
# connect to db within mongo client
mongosh admin --host "mongodb-0.mongodb-headless.default.svc.cluster.local:27017,mongodb-1.mongodb-headless.default.svc.cluster.local:27017,mongodb-2.mongodb-headless.default.svc.cluster.local:27017" --authenticationDatabase admin -u root -p $MONGODB_ROOT_PASSWORD
```

d. Add a mongo-express container and service listening on port 8081 internally for incoming traffic to render a GUI in browser.
```bash
kubectl apply -f k8s/helm-mongo-express.yaml
```

e. Add nginx-ingress-controller to route incoming traffic from Linode's NodeBalancer to the mongo-express internal ClusterIP Service. Installation of the Helm chart also automatically sets up a NodeBalancer on Linode, the public dns name of which we have to save and replace in `k8s/helm-ingress.yaml` in the `- host: ` value
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx --version 4.11.2 --set controller.publishService.enabled=true
# add Linode NodeBalancer hostname to k8s/helm-ingress.yaml 
kubectl apply -f k8s/helm-ingress.yaml
```

f. Navigate to your Nodebalancer DNS host name to access mongo-express with default credentials `admin` and `pass` to persist data. You can uninstall the database by running `helm uninstall mongodb` then start it back up with the command from step c) and see that data has been persisted in the persistent volume on Linode which are subsequently reattached to their respective pods.

### 4. Deployment of a custom NodeJS-application image published and pulled from AWS ECR, with mongodb and mongo-express pods & services running

a. Create an Elastic Container Registry (ECR) on AWS for your k8s images to live, then retrieve the push commands in aws console and run the docker login command locally to properly setup `/home/$USER/.docker/config.json`. Replace the remote url with your own and then copy the config file to your `config/` folder. It is added to .gitignore, so don't rename it.
```bash
# setup docker registry credentials
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 010928217051.dkr.ecr.eu-central-1.amazonaws.com
cp /home/$USER/.docker/config.json config/
```

b. Create secret in k8s cluster with registry credentials

Alternative 1 (allowing multiple registries to be added, since they are comma delimited in config file)
```bash
kubectl create secret generic my-registry-key-1 \
    --from-file=.dockerconfigjson=config/config.json \
    --type=kubernetes.io/dockerconfigjson
```

Alternative 2 (allowing only a single registry to be set)
```bash
kubectl create secret docker-registry my-registry-key-2 \
    --docker-server=010928217051.dkr.ecr.eu-central-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password)
```

c. Build and Push your NodeJS application image to AWS ECR remote repository. Replace the repo url with your own. Current Directory should be the git repo root dir.
```bash
docker build -t node-app:1.1 node-app/.
docker tag node-app:1.1 010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:node-app-1.1
docker push 010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:node-app-1.1
```

d. Setup environment and container secrets to avoid exposure in SCM. Create an `node-app/app/.env` file and add the following keys, changing credentials to your own:
```bash
ME_CONFIG_MONGODB_ADMINUSERNAME=admin
ME_CONFIG_MONGODB_ADMINPASSWORD=password
ME_CONFIG_MONGODB_SERVER=mongodb
ME_CONFIG_MONGODB_URL=mongodb://mongodb:27017
MONGO_DB_USERNAME=admin
MONGO_DB_PWD=password
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=password
```

Then export your AWS ECR Image URL as environment variable and test whether or not your setup is correct by running

```bash
export AWS_NODE_IMG_URL=010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:node-app-1.1
docker compose -f node-app/docker-compose.yaml up 
```
NOTE: if you are running the docker compose on a remote VPS, you have simply have to copy the `docker-compose.yaml` to your remote via scp and then copy the `node-app/app/.env` file to your remote and create an `app/` folder next to the docker compose file where the `.env` can recide. One additional step is to enter your running node-app docker container via docker exec -it CONTAINER_HASH /bin/sh and execute `vi index.html` and exchange `localhost` with your remote ip, e.g. `64.226.117.247`

TODO helper
```bash
# for node app
MONGO_DB_USERNAME=user
MONGO_DB_PWD=password
-PORT 3000
# for mongo db
MONGO_INITDB_ROOT_USERNAME=user
MONGO_INITDB_ROOT_PASSWORD=password
-volume mount in /data/db in image
-PORT 27017
# for mongo express
ME_CONFIG_MONGODB_ADMINUSERNAME=user
ME_CONFIG_MONGODB_ADMINPASSWORD=password
ME_CONFIG_MONGODB_SERVER=
ME_CONFIG_MONGODB_URL=mongodb://
-PORT 8081
```

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
    
