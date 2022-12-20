#!/bin/bash
set -eux

# github_cert_path=${GITHUB_CERT_PATH:-~/.ssh/linux_cloud_dev_ed25519}
# github_cert_file=$(basename $github_cert_path)
# github_repo=${GITHUB_REPO:-git@github.com:mesosphere/kaptain.git}

# YELLOW='\033[1;33m'
# NC='\033[0m'


# if [ -z "${GITHUB_CERT_PATH}" ] || [ -z "${GITHUB_REPO}" ]; then
#   echo -e "${YELLOW}Please set the GITHUB_CERT_PATH and GITHUB_REPO environment variables${NC}"
# fi


#Get current cer file from inventory file
cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")


#Get Host from inventory file
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")

echo Host: $host
echo Key file: $cert_path

echo Write hostname file...
echo $host > hostname

ssh -i $cert_path -R 8080:"$1":443 -N -f ubuntu@$host
ssh -i $cert_path -D 1337 -q -C -N -f ubuntu@$host
