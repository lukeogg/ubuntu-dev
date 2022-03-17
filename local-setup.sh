#!/bin/bash

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

echo Copy private key to host for GitHub...
scp -i $cert_path ~/.ssh/linux_cloud_dev_ed25519 ubuntu@$host:~/.ssh/linux_cloud_dev_ed25519
ssh -i $cert_path ubuntu@$host "echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'  >> ~/.ssh/known_hosts"

echo Checkout kudo-kubeflow repo
ssh -i $cert_path ubuntu@$host 'eval "$(ssh-agent -s)" && ssh-add ~/.ssh/linux_cloud_dev_ed25519 && git clone --recursive git@github.com:mesosphere/kaptain.git'

#ssh -i $cert_path ubuntu@$host 'export GITHUB_TOKEN=$(cat ~/.github_token)'