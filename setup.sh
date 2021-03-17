#!/bin/bash

usage() {
    echo "Usage: ./setup.sh csp_type(aws|gcp|azure)"
    exit 1
}

if [ "$1" == "" ]; then
    usage
fi

INSTALLATION_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

user=$(whoami)
nopass=$(sudo grep NOPASSWD /etc/sudoers)

# setup no sudo password for current machine
if [ "$nopass" == "" ]; then
    echo "$user ALL=(ALL) NOPASSWD: ALL" | sudo tee --append /etc/sudoers
fi

echo "||||Set up procedures, only run once!||||"
sudo apt-get update
sudo apt-get install python3 python3-pip unzip -y

# Install ansible
cd $INSTALLATION_DIRECTORY
sudo pip3 install -r requirements.txt

# Install terraform and jq
ansible-playbook setup.yaml

if [ "$1" == "gcp" ]; then
    curl https://sdk.cloud.google.com | bash
    exec -l $SHELL
    echo "||||Please run gcloud init to finish setup||||"
elif [ "$1" == "aws" ]; then
    cd $HOME
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    echo "||||Please run aws configure to finish setup||||"
elif [ "$1" == "azure" ]; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    echo "||||Please run az login to finish setup||||"
else
    echo "Not supported CSP!"
fi
