# DESCRIPTION HEADER

DESCRIPTION DETAIL

The main projects are:
- asdf

## Setup

1. Pull SCM

    Pull the repository locally by running
    ```
    git clone https://github.com/hangrybear666/10-devops-bootcamp__kubernetes.git
    ```
2. Install Minikube on your local OS (or in our case a remote VPS)

    NOTE: for local development simply follow https://minikube.sigs.k8s.io/docs/start/ 

    a. Add `SERVICE_USER_PW=xxx` to your `.env` file so the installation script can add this to the new user. Overwrite`REMOTE_ADDRESS=xxx` to yours in `config/remote.properties`

    b. Run the installation script in `scripts/` folder and type `y` if you wish to install docker before installaing minikube and `n` if docker is already installed.
    ```
    # this is aimed at Debian-like distros with the apt package manager
    ./remote-install-minikube.sh
    # If you want to remove docker and/or minikube run
    ./remote-uninstall-minikube.sh
    ``` 

## Usage (Demo Projects)

0. asd

## Usage (Exercises)

TODO
