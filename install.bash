#!/bin/bash
set -euo pipefail
#IFS=$'\n\t'

apt-get update

# not sure of we need this
apt-get install -y software-properties-common

apt-get install -y \
  build-essential \
  ca-certificates \
  checkinstall \
  curl \
  libcurl4 \
  git \
  gnupg2 \
  make \
  libssl-dev \
  libncursesw5-dev \
  libssl-dev \
  libsqlite3-dev \
  libgdbm-dev \
  libc6-dev  \
  libbz2-dev \
  liblz4-tool \
  lsb-release \
  lzop \
  pbzip2 \
  python-dev \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  remake \
  rpm \
  ruby-dev \
  tk-dev \
  tar \
  unzip


# Docker 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io


# k8s
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.14/clusterctl-linux-amd64 -o clusterctl
chmod +x ./clusterctl

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws
