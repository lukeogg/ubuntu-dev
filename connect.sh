#!/bin/bash

#Get current cer file from inventory file
cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")

#Get Host from inventory file
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")

ssh -i $cert_path ubuntu@$host/notebooks
