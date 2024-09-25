# Kubernetes manifests, helm charts, helmfiles and kubectl shell scripts to provision resources in managed Linode Kubernetes Engine

Kubernetes manifests, Helmcharts and kubectl scripts for Deployments, ConfigMaps, Secrets, PVCs, StatefulSets, internal & external Services, Ingress to deploy simple web-apps, or more complex microservices on the Linode Managed Kubernetes Engine.

<b><u>The advanced exercise projects are:</u></b>
1. Write & Read (asynchronous row-based) replicated MySQL StatefulSet & PVC Block Storage with replicated SpringBoot Java & phpmyadmin Deployment, accessed via Ingress nginx-controller - <b>started manually via kubectl apply commands</b>
2. Write & Read (asynchronous row-based) replicated MySQL StatefulSet & PVC Block Storage with replicated SpringBoot Java & phpmyadmin Deployment, accessed via Ingress nginx-controller - <b>started via shell script running helm charts</b>

<b><u>The basic course examples are:</u></b>
1. A simple app with ConfigMap, locally generated Secret to avoid SCM exposure and external LoadBalancer Service in k8s cluster
2. A simple app with ConfigMap File and Secret File Volume Mounting for initializing containers with custom files
3. Managed k8s cluster on Linode running a replicated StatefulSet application with multiple nodes and attached persistent storage volumes using Helm Charts
4. Deployment of a custom NodeJS-application image published and pulled from AWS ECR, with mongodb and mongo-express pods & services running
5. Deployment of 11 replicated microservices with best-practice configuration via single k8s.yaml file
6. Deployment of 11 replicated microservices with several helm install commands bundled in a bash script
7. Deployment of 11 replicated microservices with single helmfile apply command

<b><u>The bonus projects are:</u></b>
1. An ArgoCD deployment in Kubernetes following GitOps principles for declarative configuration versioning and storage.
2. An nginx reverse proxy to route external traffic into a remote linux VPS to an ingress-nginx-controller which forwards the requests to an internal service

## Setup

### 1. Pull SCM

Pull the repository locally by running
```
git clone https://github.com/hangrybear666/10-devops-bootcamp__kubernetes.git
```
### 2. Install Minikube on your local OS (or in our case a remote VPS)

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

### 3. Install additional dependencies

Install `jq` to parse json files. Install `openssl` to generate random passwords for environment vars.

### 4. Install helm on your local OS

See https://helm.sh/docs/intro/install/
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 5. Install helmfile on your local OS and run helmfile init to install plugins

Find the binary link for your OS at https://github.com/helmfile/helmfile/releases
```bash
curl -LO https://github.com/helmfile/helmfile/releases/download/v1.0.0-rc.4/helmfile_1.0.0-rc.4_linux_386.tar.gz
tar -xzf helmfile_1.0.0-rc.4_linux_386.tar.gz --wildcards '*helmfile'
sudo chmod +x helmfile
sudo mv helmfile /usr/bin/helmfile
helmfile init
# install plugins by agreeing with "y"
```

## Usage (Exercises)

<details closed>
<summary><b>0. Test your java / mysql / phpmyadmin application locally with docker-compose </b></summary>

a. Create `.env` file in `java-app/` folder by running the following script, generating random passwords via openssl for you.
```bash
cd scripts
./create-exercise-env-vars.sh
```

b. Add local dns name forwarding to your /etc/hosts file by adding the following entry: `127.0.0.1 my-java-app.com`

d. Navigate to `java-app/` and run
```bash
VERSION_TAG=1.0 \
DB_SERVER_OVERRIDE=mysqldb \
docker compose -f docker-compose-java-app-mysql.yaml up
```

d. Navigate to http://localhost:8085/ for phpmyadmin using `DB_USER` and `DB_PWD` for login.
Then navigate to http://my-java-app.com/ for your java app.
</details>

-----

<details closed>
<summary><b>1. Write & Read (asynchronous row-based) replicated MySQL StatefulSet & PVC Block Storage with replicated SpringBoot Java & phpmyadmin Deployment, accessed via Ingress nginx-controller - started manually via kubectl apply commands</b></summary>

a. Create an Account on the Linode Cloud and then Create a Kubernetes Cluster https://cloud.linode.com/kubernetes/clusters named `test-cluster` in your Region without High Availability (HA) Control Plane to save costs. Adding 3 Nodes with 2GB each on a shared CPU is sufficient.

b. Once the cluster is running, download `test-cluster-kubeconfig.yaml`. If your file is named differently, add it to `.gitignore` as it contains sensitive data.

c. Create an Elastic Container Registry (ECR) on AWS for your k8s images to live, then retrieve the push commands in aws console and run the docker login command locally to properly setup `/home/$USER/.docker/config.json`. Replace the remote url with your own and then copy the config file to your `config/` folder. It is added to .gitignore, so don't rename it.
```bash
# setup docker registry credentials
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 010928217051.dkr.ecr.eu-central-1.amazonaws.com
cp /home/$USER/.docker/config.json config/
```

d. Create secret from prior docker login step so kubernetes can pull the AWS ECR image
```bash
export KUBECONFIG=test-cluster-kubeconfig.yaml
kubectl create namespace exercises
kubectl create secret generic aws-ecr-config \
--from-file=.dockerconfigjson=config/config.json \
--type=kubernetes.io/dockerconfigjson \
--namespace exercises
# check if secret looks correct
kubectl get secret aws-ecr-config -n exercises --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

e. Create Secret from `java-app/.env` file created by the `./create-exercise-env-vars.sh` script in exercise step 0)
```bash
kubectl create secret generic java-app-mysql-env \
--from-env-file=java-app/.env \
--namespace exercises
# check if secret looks correct
kubectl get secret java-app-mysql-env -n exercises -o yaml

```

f. Add nginx-ingress-controller to route incoming traffic from Linode's NodeBalancer to the phpmyadmin & java-app internal ClusterIP Service. Installation of the Helm chart also automatically sets up a NodeBalancer on Linode, the public dns name of which we have to save and replace in `k8s/exercises/01-ingress-configuration.yaml` in the `- host: ` value
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx --version 4.11.2 --namespace exercises
```

g. Before building and pushing the docker image to remote, change the HOST variable in line 48 of your `java-app/src/main/resources/static/index.html` to your Linode NodeBalancer DNS Name, for example:
```js
const HOST = "172-xxx-xxx-124.ip.linodeusercontent.com";
```

h. Build and Push your java application image to AWS ECR remote repository. Replace the repo url with your own. Current Directory should be the git repo root dir.
```bash
docker build -t java-app:2.3 java-app/.
docker tag java-app:2.3 010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:java-app-2.3
docker push 010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:java-app-2.3
```

i. To start mysql StatefulSet (replicas:2), attached to 10GB each of persistent linode block storage volume, launch the java application (replicas:2) and start phpmyadmin UI, with an ingress-nginx controller for external access, replace the following values and then run the script.

*NOTE: replace image name in `k8s/exercises/01-java-app-deployment.yaml` with your own*

*NOTE: replace hostname in `k8s/exercises/01-ingress-configuration.yaml` with your Linode NodeBalancer dns name in <b>both</b> Ingress resources*

*NOTE: replace pma-absolute-uri in `k8s/exercises/01-phpmyadmin-configmap.yaml` with your own but it <b>has</b> to end with `/phpmyadmin/` or the Ingress Regex Path Redirect won't work*

```bash
kubectl apply -f k8s/exercises/01-mysql-configmap.yaml
kubectl apply -f k8s/exercises/01-mysql-service.yaml
kubectl apply -f k8s/exercises/01-mysql-statefulset.yaml
# change java image name to your own remote ecr img
kubectl apply -f k8s/exercises/01-java-app-deployment.yaml
# replace Linode NodeBalancer hostname in pma-absolute-uri
kubectl apply -f k8s/exercises/01-phpmyadmin-configmap.yaml
kubectl apply -f k8s/exercises/01-phpmyadmin-deployment.yaml
# add Linode NodeBalancer hostname to both Ingress resources
kubectl apply -f k8s/exercises/01-ingress-configuration.yaml

```

j. Access the java application on your Linode NodeBalancer DNS Name's root url  `http://172-xxx-xxx-124.ip.linodeusercontent.com`

k. Access phpmyadmin on your Linode NodeBalancer DNS Name's root url followed by `/phpmyadmin/` including the last forward slash (!) for example `http://172-xxx-xxx-124.ip.linodeusercontent.com/phpmyadmin/`

<details closed>
<summary><b>Commands to connect to db, debug, delete all resources</b></summary>

```bash
kubectl run -it --rm --namespace=exercises --image=mysql:9.0.1 --restart=Never mysql-client -- mysql -h mysqldb -pa+XMLuFoJR6NQnHk
# debug
kubectl describe statefulset mysql -n exercises
kubectl describe deployment java-app -n exercises
kubectl describe deployment phpmyadmin -n exercises

# delete all resources
kubectl delete -f k8s/exercises/01-mysql-statefulset.yaml
kubectl delete -f k8s/exercises/01-mysql-service.yaml
kubectl delete -f k8s/exercises/01-mysql-configmap.yaml
kubectl delete -f k8s/exercises/01-java-app-deployment.yaml
kubectl delete -f k8s/exercises/01-phpmyadmin-deployment.yaml
kubectl delete -f k8s/exercises/01-phpmyadmin-configmap.yaml
kubectl delete -f k8s/exercises/01-ingress-configuration.yaml
kubectl delete pvc data-mysql-0 data-mysql-1 data-mysql-2 -n exercises
kubectl delete secret java-app-mysql-env -n exercises
kubectl delete secret aws-ecr-config -n exercises
# keep to retain nodebalancer dns name
helm uninstall nginx-ingress --namespace exercises

#             __   __           __        ___  __     ___  __
#   |\/| \ / /__` /  \ |       /  \ |  | |__  |__) | |__  /__`
#   |  |  |  .__/ \__X |___    \__X \__/ |___ |  \ | |___ .__/
source java-app/.env
# create new database with root user and insert
kubectl run mysql-client --image=mysql:5.7 -i --rm --namespace=exercises --restart=Never --\
  mysql -h mysql-0.mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE test;
CREATE TABLE test.messages (id INT AUTO_INCREMENT PRIMARY KEY, message VARCHAR(250));
INSERT INTO test.messages (message) VALUES ('hello from master replica mysql-0.mysql');
EOF

# this should throw an error since it tries to insert into read-only replica
kubectl run mysql-client --image=mysql:5.7 -i --rm --namespace=exercises --restart=Never --\
  mysql -h mysql-1.mysql -u root -p$MYSQL_ROOT_PASSWORD <<EOF
INSERT INTO test.messages (message) VALUES ('hello from read-only replica mysql-1.mysql');
EOF

# select all messages
kubectl run mysql-client --image=mysql:5.7 -i --rm --namespace=exercises --restart=Never --\
  mysql -h mysql-0.mysql -u root -p$MYSQL_ROOT_PASSWORD test <<EOF
SELECT
    message
FROM messages;
EOF

# query data inserted by java-app
kubectl run mysql-client --image=mysql:5.7 -i --rm --namespace=exercises --restart=Never --\
  mysql -h mysql-read -u $MYSQL_USER -p$MYSQL_PASSWORD team-member-projects <<EOF
SELECT member_name, member_role FROM team_members;
EOF

# loop through read replicas
kubectl run mysql-client-loop --image=mysql:5.7 -i -t --rm --namespace=exercises --restart=Never --  bash -ic "while sleep 1; do mysql -h mysql-read -u root -p$MYSQL_ROOT_PASSWORD -e 'SELECT @@server_id,NOW(), (SELECT message from test.messages ORDER BY id desc LIMIT 1) as testquery'; done"

```
</details>

</details>

-----

<details closed>
<summary><b>2. Write & Read (asynchronous row-based) replicated MySQL StatefulSet & PVC Block Storage with replicated SpringBoot Java & phpmyadmin Deployment, accessed via Ingress nginx-controller - started via shell script running helm charts</b></summary>

a. Create an Account on the Linode Cloud and then Create a Kubernetes Cluster https://cloud.linode.com/kubernetes/clusters named `test-cluster` in your Region without High Availability (HA) Control Plane to save costs. Adding 3 Nodes with 2GB each on a shared CPU is sufficient.

b. Once the cluster is running, download `test-cluster-kubeconfig.yaml`. If your file is named differently, add it to `.gitignore` as it contains sensitive data.

c. Navigate to scripts folder and run the shell script providing your AWS ECR url, AWS ECR repo name, NodeBalancer Public DNS, and desired Java Application version. The script then 1) logs in to aws ecr 2) exports kubeconfig 3) creates namespace and secrets 4) installs nginx ingress 5) replaces the index.html HOST address with your Nodebalancer DNS Name 6) builds and pushes the java app image 7) installs the helmchart
```bash
cd scripts
./helm-launch-exercises.sh
cd .. && watch -n 5 'kubectl get all -n exercises'
```
d. Access the java application on your Linode NodeBalancer DNS Name's root url  `http://172-xxx-xxx-124.ip.linodeusercontent.com`

e. Access phpmyadmin on your Linode NodeBalancer DNS Name's root url followed by `/phpmyadmin/` including the last forward slash (!) for example `http://172-xxx-xxx-124.ip.linodeusercontent.com/phpmyadmin/`

```bash
# to delete all resources
./helm-teardown-exercises.sh
```
</details>

-----


## Usage (basic course examples)

<details closed>
<summary><b>1. Deploy a simple application with ConfigMap, locally generated Secret to avoid SCM exposure and external LoadBalancer Service in k8s cluster</b></summary>


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

```bash
MONGO_POD=$(kubectl get pods --no-headers | grep "mongodb-deployment" | awk '{print $1}')
EXPRESS_POD=$(kubectl get pods --no-headers | grep "mongo-express" | awk '{print $1}')
kubectl describe pod $MONGO_POD
kubectl logs $EXPRESS_POD
kubectl describe service mongodb-service
kubectl get all | grep mongo
```
</details>

-----

<details closed>
<summary><b>2. Deploy ConfigMap File and Secret File Volume Mounting for initializing containers with custom files</b></summary>


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
</details>

-----

<details closed>
<summary><b>3. Start a Managed k8s cluster on Linode and run a replicated StatefulSet application with multiple nodes and attached persistent storage volumes using Helm Charts</b></summary>


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
</details>

-----

<details closed>
<summary><b>4. Deployment of a custom NodeJS-application image published and pulled from AWS ECR, with mongodb and mongo-express pods & services running</b></summary>


a. Create an Elastic Container Registry (ECR) on AWS for your k8s images to live, then retrieve the push commands in aws console and run the docker login command locally to properly setup `/home/$USER/.docker/config.json`. Replace the remote url with your own and then copy the config file to your `config/` folder. It is added to .gitignore, so don't rename it.
```bash
# setup docker registry credentials
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 010928217051.dkr.ecr.eu-central-1.amazonaws.com
cp /home/$USER/.docker/config.json config/
```

b. Build and Push your NodeJS application image to AWS ECR remote repository. Replace the repo url with your own. Current Directory should be the git repo root dir.
```bash
docker build -t node-app:1.5 node-app/.
docker tag node-app:1.5 010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:node-app-1.5
docker push 010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:node-app-1.5
```

c. Create secret in k8s cluster with registry credentials

Alternative 1 (allowing multiple registries to be added, since they are comma delimited in config file)
```bash
kubectl create secret generic my-registry-key-1 \
    --from-file=.dockerconfigjson=config/config.json \
    --type=kubernetes.io/dockerconfigjson
```

Alternative 2 (allowing only a single registry to be set)
NOTE: To use this, overwrite `imagePullSecrets:- name: my-registry-key-1` in `k8s/node-app-deployment.yaml`
```bash
kubectl create secret docker-registry my-registry-key-2 \
    --docker-server=010928217051.dkr.ecr.eu-central-1.amazonaws.com \
    --docker-username=AWS \
    --docker-password=$(aws ecr get-login-password)
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
export AWS_NODE_IMG_URL=010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:node-app-1.5
docker compose -f node-app/docker-compose.yaml up
```
NOTE: if you are running the docker compose on a remote VPS, you have simply have to copy the `docker-compose.yaml` to your remote via scp and then copy the `node-app/app/.env` file to your remote and create an `app/` folder next to the docker compose file where the `.env` can recide. One additional step is to enter your running node-app docker container via docker exec -it CONTAINER_HASH /bin/sh and execute `vi index.html` and exchange `localhost` with your remote ip, e.g. `64.226.117.247`

e. Replace `image: 010928217051.dkr.ecr.eu-central-1.amazonaws.com/k8s-imgs:node-app-1.5` with your own AWS ECR image-tag in the file `k8s/node-app-deployment.yaml` and run the following commands

IMPORTANT: `mongo-root-username` and `mongo-root-password` have to be identical to the ones in your `.env` file from step d)!
```bash
kubectl create secret generic mongodb-secret \
    --namespace=default \
    --from-literal=mongo-root-username='admin' \
    --from-literal=mongo-root-password='password'
kubectl apply -f k8s/mongodb.yaml
kubectl apply -f k8s/mongo-configmap.yaml
kubectl apply -f k8s/mongo-express.yaml
kubectl apply -f k8s/node-app-deployment.yaml
```

f. Since your ip will differ from mine and also the docker-compose variant and depends on the minikube cluster configuration, we have to exec a shell in the node-app pod and replace `localhost` in `index.html` with our minikube ip and the port with our loadbalancer nodeport
```bash
NODE_APP_POD_NAME=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep "node-app")
kubectl exec -it $NODE_APP_POD_NAME -- /bin/sh
vi index.html # and replace localhost with your minikube ip and 3000 with your loadbalancer nodeport!
# then access minicube-ip:30001 in the browser or run
minikube service node-app-service
```
</details>

-----

<details closed>
<summary><b>5. Deployment of 11 replicated microservices with best-practice configuration via single k8s.yaml file</b></summary>


NOTE: The microservices app is a google developed multi-language application with service-to-service communication via gRPC. See https://github.com/GoogleCloudPlatform/microservices-demo/tree/main

a. Create an Account on the Linode Cloud and then Create a Kubernetes Cluster https://cloud.linode.com/kubernetes/clusters named `test-cluster` in your Region without High Availability (HA) Control Plane to save costs. Adding 3 Nodes with 4GB each on a shared CPU is sufficient.

b. Once the cluster is running, download `test-cluster-kubeconfig.yaml`. If your file is named differently, add it to `.gitignore` as it contains sensitive data.

Then run:
```bash
# change permissions for downloaded kubeconfig
chmod 400 test-cluster-kubeconfig.yaml
export KUBECONFIG=test-cluster-kubeconfig.yaml
kubectl get nodes
```

c. Start the microservice application including a LoadBalancer receiving an external DNS Name from your Linode NodeBalancer for public access.

```bash
kubectl apply -f k8s/microservices-best-practice.yaml
#kubectl delete -f k8s/microservices-best-practice.yaml
```

d. Navigate to your Nodebalancer DNS host name to access the microservices frontend.
</details>

-----

<details closed>
<summary><b>6. Deployment of 11 replicated microservices with several helm install commands bundled in a bash script</b></summary>

a. Simply execute the following command from the git project root directory
```bash
export KUBECONFIG=test-cluster-kubeconfig.yaml
# install
bash scripts/helm-install-microservices.sh
# uninstall
bash scripts/helm-uninstall-microservices.sh
```
</details>

-----

<details closed>
<summary><b>7. Deployment of 11 replicated microservices with single helmfile apply command</b></summary>

a. Simply execute the following command from the git project root directory

```bash
# install
KUBECONFIG=$(pwd)/test-cluster-kubeconfig.yaml \
helmfile apply \
--file helm/helmfile.yaml \
-n microservices
# uninstall
KUBECONFIG=$(pwd)/test-cluster-kubeconfig.yaml \
helmfile destroy \
--file helm/helmfile.yaml \
-n microservices
```
</details>

-----

## Usage (Bonus Remote VPS Setup)

<details closed>
<summary><b>1. Setup ArgoCD to use GitOps principles for writing declarative configuration, versioning, storing and running our k8s cluster </b></summary>

See https://argo-cd.readthedocs.io/en/stable/getting_started/

a. Add `ARGOCD_ADMIN_PW=xxx` to `.env` file

b. Navigate to `scripts/` folder and execute the installation script.
```bash
./remote-setup-ArgoCD.sh
```
</details>

-----

<details closed>
<summary><b>2. Setup ingress-nginx for minikube to handle incoming traffic from the outside world into our remote VPS</b></summary>
See https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

a. Navigate to `scripts/` folder and execute the installation script.
```bash
./remote-setup-ingress-nginx.sh
```

b. Install nginx reverse proxy to forward outside requests to the VPS to the minikube ip address on the ingress controller port. To configure nginx replace `proxy_pass` ip with your minikube ip from the output of step a)
```bash
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

</details>
