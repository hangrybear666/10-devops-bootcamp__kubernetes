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

0. First of all, we want to setup ArgoCD to use GitOps principles for writing declarative configuration, versioning, storing and running our k8s cluster 

    See https://argo-cd.readthedocs.io/en/stable/getting_started/

    a. Add `ARGOCD_ADMIN_PW=xxx` to `.env` file

    b. Navigate to `scripts/` folder and execute the installation script.
    ```
    ./remote-setup-ArgoCD.sh
    ```

1. We also want to setup ingress-nginx for minikube to handle incoming traffic 

    See https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/

    a. Navigate to `scripts/` folder and execute the installation script.
    ```
    ./remote-setup-ingress-nginx.sh
    ```
    
## Usage (Exercises)

TODO
