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
echo Key file: $PWD/$cert_path

echo Write ssh config file...
echo "" >> ~/.ssh/config
echo "Host $host" >> ~/.ssh/config
echo "    User ubuntu" >> ~/.ssh/config
echo "    HostName $host" >> ~/.ssh/config
echo "    IdentityFile $PWD/$cert_path" >> ~/.ssh/config
#echo "    LocalForward 127.0.0.1:8080 172.18.255.200:443" >> ~/.ssh/config
#echo "    LocalForward 127.0.0.1:1337 127.0.0.1:1337" >> ~/.ssh/config

# This script is used to open a remote VSCode session.
#code --folder-uri=vscode-remote://$host/home/go/src/github.com/mesosphere/dkp-insights/

