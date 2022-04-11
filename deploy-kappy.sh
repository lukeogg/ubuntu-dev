#!/bin/bash


#==================================== Get Expiration Time ==========================================#
#read -p "- Enter the number of hours (1-36) you want to run the cluster for.  Leave empty for 10h: " EXPIRATION_TIME
#re='^(\s*|[1-9]|[12]\d|3[0-6])$'
#while ! [[ $EXPIRATION_TIME =~ $re ]]
#do
#    read -p "- Enter the number of hours you want to run the cluster for.  Leave empty for 10h: " EXPIRATION_TIME
#done


if [ -z "$EXPIRATION_TIME" ]
then
    echo "
        You can export EXPIRATION_TIME with an integer for hours to timeout.  Default is 10
        "
    EXPIRATION_TIME=10h
else
    EXPIRATION_TIME="$EXPIRATION_TIMEh"
fi				

echo "EXPIRATION_TIME=$EXPIRATION_TIME"
sleep 4

#==================================== Default Variables ==========================================#
# Get Host from inventory file
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")
#Get current cer file from inventory file
cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")
echo Host: $host
echo Key file: $cert_path


#==================================== Obtain AWS Credentials ==========================================#
eval $(maws li 327650738955_Mesosphere-PowerUser)


#==================================== Deploy Cluster =============================================#

ssh -T -i $cert_path ubuntu@$host << HEREDOC
    sudo apt-get update 
    cd kudo-kubeflow 
    sudo usermod -aG docker ubuntu
    newgrp docker
    make clean-all
    ~/dkp delete bootstrap --kubeconfig $HOME/.kube/config
    unset KUBECONFIG
    make cluster-create kommander-install install
HEREDOC