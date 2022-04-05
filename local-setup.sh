#!/bin/bash

GITHUB_CERT_PATH="${GITHUB_CERT_PATH:-''}"
GITHUB_REPO="${GITHUB_REPO:-''}"

if [ -z "${GITHUB_CERT_PATH}" ] || [ -z "${GITHUB_REPO}" ]; then
  echo "GITHUB_CERT_PATH and GITHUB_REPO must be set"
  exit 1
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

echo Copy private key to host for GitHub...
scp -i $cert_path ${GITHUB_CERT_PATH} ubuntu@$host:${GITHUB_CERT_PATH}
ssh -i $cert_path ubuntu@$host "echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'  >> ~/.ssh/known_hosts"

echo Checkout the repo
ssh -i $cert_path ubuntu@$host 'eval "$(ssh-agent -s)" && ssh-add ${GITHUB_CERT_PATH} && git clone --recursive ${GITHUB_REPO}'