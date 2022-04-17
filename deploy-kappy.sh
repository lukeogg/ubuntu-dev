#!/bin/bash


#==================================== Get Expiration Time ==========================================#
#read -p "- Enter the number of hours (1-36) you want to run the cluster for.  Leave empty for 10h: " EXPIRATION_TIME
#re='^(\s*|[1-9]|[12]\d|3[0-6])$'
#while ! [[ $EXPIRATION_TIME =~ $re ]]
#do
#    read -p "- Enter the number of hours you want to run the cluster for.  Leave empty for 10h: " EXPIRATION_TIME
#done


# check for AWS_EXPIRATION, and GPU_ENABLED variables
if [ -z "$AWS_EXPIRATION" ]
then
    echo "
        You need to export AWS_EXPIRATION with an integer for hours to timeout.  
        Example: export AWS_EXPIRATION=12h
        "
    exit 1
fi				

if [ -z "$GPU_ENABLED" ]
then
    echo "
        You need to export GPU_ENABLED with a boolean for GPU support.
        "
    exit 1
fi

if [ -z "$MAWS_ACCOUNT" ]
then
    echo "
        You need to export MAWS_ACCOUNT to continue
        "
    exit 1
fi

echo "AWS_EXPIRATION=$AWS_EXPIRATION"
echo "GPU_ENABLED=$GPU_ENABLED"
echo "MAWS_ACCOUNT=$MAWS_ACCOUNT"



#==================================== Default Variables ==========================================#
# Get Host from inventory file
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")
#Get current cer file from inventory file
cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")
echo Host: $host
echo Key file: $cert_path


#==================================== Obtain AWS Credentials ==========================================#
eval $(maws li "$MAWS_ACCOUNT")


#==================================== Deploy Cluster =============================================#

ssh -T -i $cert_path ubuntu@$host 'sudo mv ~/kubectl //usr/local/bin/kubectl'

ssh -T -i $cert_path ubuntu@$host << HEREDOC
    cd ~/kudo-kubeflow

    sudo usermod -aG docker ubuntu
    newgrp docker

    make clean-all
    
    export AWS_EXPIRATION="$AWS_EXPIRATION" GPU_ENABLED="$GPU_ENABLED"
    echo "
        AWS_EXPIRATION=\$AWS_EXPIRATION GPU_ENABLED=\$GPU_ENABLED
    "

    ~/kaptain/tools/dkp/dkp.sh delete bootstrap --kubeconfig $HOME/.kube/config
    unset KUBECONFIG
    
    make cluster-create kommander-install install
HEREDOC