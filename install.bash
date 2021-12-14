#!/bin/bash
set -euo pipefail
#IFS=$'\n\t'

# kommander_version=${KOMMANDER_VERSION:-v2.1.0}
# dkp_version=${DKP_VERSION:-v2.1.0}

# sudo yum -y update
# sudo yum install -y \
#   yum-utils \
#   epel-release
# sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
# sudo yum install -y \
#   docker-ce docker-ce-cli \
#   containerd.io \
#   unzip \
#   bzip2 \
#   ansible \
#   tinyproxy
# sudo systemctl start docker
# sudo systemctl enable docker
# sudo usermod -aG docker "$(whoami)"
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x ./kubectl
# curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.3.14/clusterctl-linux-amd64 -o clusterctl
# chmod +x ./clusterctl

function _wget {
  wget --progress=dot -e dotbytes=1M "$@"
}

function addRepos {
  apt-get update
  apt-get install -y software-properties-common
  # apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
  add-apt-repository -y ppa:deadsnakes/ppa
  #add-apt-repository -y ppa:git-core/ppa
}

function addDocker {(
#  _wget -qO- https://get.docker.com/ | sh
  dist="$(lsb_release -sc)"
  local dist=${dist}
  cd /tmp
  local containerd_deb="containerd.io_1.2.13-2_amd64.deb"
  _wget https://download.docker.com/linux/ubuntu/dists/${dist}/pool/stable/amd64/${containerd_deb}
  local docker_deb="docker-ce_19.03.12~3-0~ubuntu-${dist}_amd64.deb"
  _wget https://download.docker.com/linux/ubuntu/dists/${dist}/pool/stable/amd64/${docker_deb}
  local docker_cli_deb="docker-ce-cli_19.03.12~3-0~ubuntu-${dist}_amd64.deb"
  _wget https://download.docker.com/linux/ubuntu/dists/${dist}/pool/stable/amd64/${docker_cli_deb}

  # install some packages that make aufs possible, and satisfies docker version dependencies
  apt-get install -y \
    aufs-tools \
    linux-image-extra-virtual \
    libseccomp2 >= 2.3.0 \
    libltdl7  # this is a dependency in the deb
  dpkg -i $containerd_deb $docker_deb $docker_cli_deb
  echo -n -e "DOCKER=/usr/bin/docker\n" >> /opt/teamcity-agent/conf/buildAgent.properties
  echo -n -e "DOCKER_VERSION=$(docker --version | sed -rn 's/Docker\ version\ (.*?), build [0-9a-f]+/\1/p')\n" >> /opt/teamcity-agent/conf/buildAgent.properties
  rm $docker_deb
)}

function configureDocker {
  mkdir -p /etc/systemd/system/docker.service.d
  cat > /etc/systemd/system/docker.service.d/overrides.conf <<EOF
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -H fd:// --graph=/mnt --storage-driver=overlay
EOF

  # Currently Docker does not enable the systemd service by default
  systemctl daemon-reload
  systemctl enable docker
}

function moveCredentialFilesIntoPlace() {
  # The file provisioner provided by packer will only upload files as the user
  # that it uses to ssh to the box.  This means that the files can only be
  # written some place the current user can write to.
  # To work around this fact, the whole directory is uploaded into /tmp
  # and the files can then be moved into place by this script.
  # See https://github.com/mitchellh/packer/issues/1551 for details.

  mkdir -p /root/.m2
  mv /tmp/agent-fs/root/.m2/settings-security.xml /root/.m2/settings-security.xml
  echo -n -e "MVN_SETTINGS_SECURITY=mesosphere\n" >> /opt/teamcity-agent/conf/buildAgent.properties

  mv /tmp/agent-fs/root/.gnupg /root/.gnupg
  mv /tmp/agent-fs/root/.gnupg_dcos-cosmos /root/.gnupg_dcos-cosmos
  echo -n -e "GPG2_KEYS=mesos-rxjava,dcos-cosmos\n" >> /opt/teamcity-agent/conf/buildAgent.properties

  mv /tmp/agent-fs/root/.sbt /root/.sbt

  rm -rf /tmp/agent-fs

}

#export DEBIAN_FRONTEND=noninteractive
env | sort

# we do that at the very beginning as it is crucial
#onAWS && moveSymlinkEtcResolvConfScriptToCloudInit

addRepos

apt-get update
apt-get install -y \
  autoconf \
  automake \
  build-essential \
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
  lzop \
  openjdk-8-jdk-headless \
  pbzip2 \
  python-dev \
  python-pip \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  pxz \
  remake \
  rpm \
  ruby-dev \
  tk-dev \
  tar \
  unzip

apt-get dist-upgrade -y

echo -n -e "GPG2=/usr/bin/gpg2\n" >> /opt/teamcity-agent/conf/buildAgent.properties

addDocker

apt-get autoremove -y

gem update --system 3.0.5 && gem install fpm

pip3 install --upgrade pip==9.0.3 && pip3 install tox httpie

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf ./aws

apt-get install -y python3.4 python3.4-dev
apt-get install -y python3.5 python3.5-dev


echo "cat /opt/teamcity-agent/conf/buildAgent.properties"
cat /opt/teamcity-agent/conf/buildAgent.properties