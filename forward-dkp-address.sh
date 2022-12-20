#!/bin/bash
set -eux

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
