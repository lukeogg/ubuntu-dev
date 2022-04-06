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
ssh -i $cert_path ubuntu@$host "echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'  >> ~/.ssh/known_hosts"

echo Checkout the repo
ssh -i $cert_path ubuntu@$host eval "$(ssh-agent -s)" && ssh-add ~/.ssh/$github_cert_file && git clone --recursive $github_repo