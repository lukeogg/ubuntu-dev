#!/bin/bash

github_cert_path=${GITHUB_CERT_PATH:-~/.ssh/linux_cloud_dev_ed25519}
github_cert_file=$(basename $github_cert_path)
github_repo=${GITHUB_REPO:-git@github.com:mesosphere/kaptain.git}

YELLOW='\033[1;33m'
NC='\033[0m'


if [ -z "${GITHUB_CERT_PATH}" ] || [ -z "${GITHUB_REPO}" ]; then
  echo -e "${YELLOW}Please set the GITHUB_CERT_PATH and GITHUB_REPO environment variables${NC}"
fi

if [ -n "$1" ]; then
    cert_path = $1
else
    #Get current cer file from inventory file
    cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")
fi

#Get Host from inventory file
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")

echo Host: $host
echo Key file: $cert_path

echo Write hostname file...
echo $host > hostname

echo Copy private key ${github_cert_path} to host for GitHub...
scp -i $cert_path ${github_cert_path} ubuntu@$host:~/.ssh/

echo Copy bootstrap script to home directory...
scp -i $cert_path bootstrap.sh ubuntu@$host:~/bootstrap.sh

# Add Public Key to known_hosts
a=$(cat ${github_cert_path}.pub)
arr=($a)
known_host=${arr[@]:0:2}
ssh -i $cert_path ubuntu@$host "ssh-keyscan github.com >> ~/.ssh/known_hosts"

# docker permissions
ssh -i $cert_path ubuntu@$host "sudo usermod -aG docker ubuntu"

echo Checkout the repo

ssh -i $cert_path ubuntu@$host 'mkdir -p ~/go/src/github.com/mesosphere && cd ~/go/src/github.com/mesosphere && eval "$(ssh-agent)" && ssh-add ~/.ssh/'$github_cert_file' && git clone --recursive 'git@github.com:mesosphere/dkp-insights.git


# set .env
echo DOCKER_USERNAME=${DOCKER_USERNAME} >> bashrc
echo DOCKER_PASSWORD=${DOCKER_PASSWORD} >> bashrc
echo GITHUB_TOKEN=${GITHUB_TOKEN} >> bashrc

# set .bashrc
scp -i $cert_path bashrc ubuntu@$host:~/bashrc
ssh -i $cert_path ubuntu@$host "mv bashrc .bashrc"

scp -i $cert_path gitconfig ubuntu@$host:~/.gitconfig

git checkout bashrc
