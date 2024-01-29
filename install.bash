#!/bin/bash
set -euo pipefail

apt-get update

apt-get install -y \
  curl \
  git \
  gnupg2 \
  make \
  pbzip2 \
  python3 \
  python3-pip \
  python3-venv \
  tar \
  unzip \
  iotop \
  fio \
  sysstat \
  strace \
  xdg-utils \
  jq


# Docker
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io

# pip install
pip install pre-commit #for kommander

usermod -aG docker ubuntu

# k8s
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.14/clusterctl-linux-amd64 -o clusterctl
chmod +x ./clusterctl
mv ./clusterctl /usr/local/bin/clusterctl

# Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# GoLang
wget https://dl.google.com/go/go1.20.13.linux-amd64.tar.gz
sudo tar -C /usr/local/ -xzf go1.20.13.linux-amd64.tar.gz
rm go1.20.13.linux-amd64.tar.gz

# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws

# k9s
curl -L -O https://github.com/derailed/k9s/releases/download/v0.26.7/k9s_Linux_x86_64.tar.gz
tar xf k9s_Linux_x86_64.tar.gz
mv k9s /usr/local/bin
rm k9s_Linux_x86_64.tar.gz

mkdir -p /home/ubuntu/go/src/github.com/mesosphere
chown -R ubuntu:ubuntu go

# kuttl
curl -L -O https://github.com/kudobuilder/kuttl/releases/download/v0.15.0/kuttl_0.15.0_linux_x86_64.tar.gz
tar xf kuttl_0.15.0_linux_x86_64.tar.gz
mv kubectl-kuttl /usr/local/bin
rm kuttl_0.15.0_linux_x86_64.tar.gz

# GH CLI
snap install gh

# asdf
git clone https://github.com/asdf-vm/asdf.git /home/ubuntu/.asdf --branch v0.11.3
sudo chown -R ubuntu:ubuntu /home/ubuntu/.asdf

# Fix pod errors due to “too many open files” (https://kind.sigs.k8s.io/docs/user/known-issues/#pod-errors-due-to-too-many-open-files)
sysctl fs.inotify.max_user_watches=524288
sysctl fs.inotify.max_user_instances=512
