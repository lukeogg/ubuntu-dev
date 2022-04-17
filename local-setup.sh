#!/bin/bash

github_cert_path=${GITHUB_CERT_PATH:-~/.ssh/linux_cloud_dev_ed25519}
github_cert_file=$(basename $github_cert_path)
github_repo=${GITHUB_REPO:-git@github.com:mesosphere/kaptain.git}

if [ -z "$GIT_USER" ]
then
    echo "
        You need to export GIT_USER to configure GIT in the remote machine
        "
    exit 1
else
    echo "GIT_USER=$GIT_USER"
fi

if [ -z "$GIT_EMAIL" ]
then
    echo "
        You need to export GIT_EMAIL to configure GIT in the remote machine
        "
    exit 1
else
    echo "GIT_EMAIL=$GIT_EMAIL"
fi

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

# Add Public Key to known_hosts
ssh -i $cert_path ubuntu@$host "ssh-keyscan github.com >> ~/.ssh/known_hosts"

echo Checkout the repo

ssh -i $cert_path ubuntu@$host 'eval "$(ssh-agent -s)" && ssh-add ~/.ssh/'$github_cert_file' && git clone --recursive '$github_repo

ssh -i $cert_path ubuntu@$host "sudo mv ~/kubectl //usr/local/bin/"

ssh -i $cert_path ubuntu@$host "git config --global user.name $GIT_USER && git config --global user.email $GIT_EMAIL"