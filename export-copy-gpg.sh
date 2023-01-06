#!/bin/bash
set -eux

# Get current cer file from inventory file
cert_path=$(cat inventory | ggrep -Po "(?<==).*\.pem")

# Get Host from inventory file
host=$(cat inventory | ggrep -Po "(.*)amazonaws\.com")

gpg_key=$(gpg --list-secret-keys | grep -Eo "[A-Z0-9]{40}")

echo Host: $host
echo Key file: $cert_path

gpg --export-secret-keys ${gpg_key} > private.key

echo Copy private key ${gpg_key} to host...
scp -i $cert_path private.key ubuntu@$host:~/

ssh -i $cert_path ubuntu@$host "gpg --import ~/private.key"
ssh -i $cert_path ubuntu@$host "rm ~/private.key"
rm private.key
