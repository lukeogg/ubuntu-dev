#!/bin/bash


# ==================================== Get Expiration Time ========================================== #
#read -p "- Enter the number of hours (1-36) you want to run the cluster for.  Leave empty for 10h: " EXPIRATION_TIME
#re='^(\s*|[1-9]|[12]\d|3[0-6])$'
#while ! [[ $EXPIRATION_TIME =~ $re ]]
#do
#    read -p "- Enter the number of hours you want to run the cluster for.  Leave empty for 10h: " EXPIRATION_TIME
#done


# check for AWS_EXPIRATION, and GPU_ENABLED variables
aws_expiration=${AWS_EXPIRATION:-10h}
gpu_enabled=${GPU_ENABLED:-false}
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")  # Get Host from inventory file
cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")  # Get current cer file from inventory file

yellow='\033[1;33m'
nc='\033[0m'

if [ -z "$MAWS_ACCOUNT" ]; then
    read -p "Please enter an AWS account to continue..."$'\n' MAWS_ACCOUNT
fi

echo "
    AWS expiration: ${aws_expiration}
    AWS account: ${MAWS_ACCOUNT}
    GPU enabled: ${gpu_enabled}
    Host: ${host}
    Key file: ${cert_path}
    "

# ==================================== Obtain AWS Credentials ========================================== #
eval $(maws li "$MAWS_ACCOUNT")


# ==================================== Deploy Cluster ============================================= #
ssh -T -i $cert_path ubuntu@$host << HEREDOC
    if [ -e ~/kubectl ]; then
        sudo mv ~/kubectl //usr/local/bin/kubectl
    fi

    cd ~/kudo-kubeflow

    sudo usermod -aG docker ubuntu
    newgrp docker

    make clean-all

    export aws_expiration="$aws_expiration" gpu_enabled="$gpu_enabled"

    ~/kaptain/tools/dkp/dkp.sh delete bootstrap
    unset KUBECONFIG
    
    make cluster-create kommander-install install
HEREDOC