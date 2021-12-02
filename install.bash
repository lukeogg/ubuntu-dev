#!/bin/bash
set -euo pipefail

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

function installPacker {(
  cd /tmp
  wget https://releases.hashicorp.com/packer/1.6.0/packer_1.6.0_linux_amd64.zip
  unzip -d /usr/local/bin/ packer_1.6.0_linux_amd64.zip
  echo -n -e "PACKER=/usr/local/bin/packer\n" >> /opt/teamcity-agent/conf/buildAgent.properties
  echo -n -e "PACKER_VERSION=$(packer --version)\n" >> /opt/teamcity-agent/conf/buildAgent.properties
)}

function installOracleJDK8 {(
  cd /opt
  _wget https://downloads.mesosphere.io/java/jdk-8u51-linux-x64.tar.gz
  tar xzf jdk-*-linux-x64.tar.gz
  rm jdk-*-linux-x64.tar.gz

  echo -E "env.JDK_18=$(find /opt/ -maxdepth 1 -name jdk1.8.0_\*)" >> /opt/teamcity-agent/conf/buildAgent.properties
  echo -E "env.JDK_18_x64=$(find /opt/ -maxdepth 1 -name jdk1.8.0_\*)" >> /opt/teamcity-agent/conf/buildAgent.properties

)}

function installjq {(
  cd /usr/bin
  _wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
  chmod +x jq
  echo -n -e "JQ=/usr/bin/jq\n" >> /opt/teamcity-agent/conf/buildAgent.properties
  echo -n -e "JQ_VERSION=$(jq --version 2>&1 | sed -rn 's/jq-([[:digit:]]\.[[:digit:]]+(\.[[:digit:]]+)?)/\1/p')\n" >> /opt/teamcity-agent/conf/buildAgent.properties
)}

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

# function installTeamCityAgent {(
#   mkdir /opt/teamcity-agent
#   cd /opt/teamcity-agent
#   _wget https://teamcity.mesosphere.io/update/buildAgent.zip
#   unzip buildAgent.zip
#   rm buildAgent.zip

#   mkdir /teamcity
#   sed 's/^serverUrl=.*/serverUrl=https:\/\/teamcity.mesosphere.io/' /opt/teamcity-agent/conf/buildAgent.dist.properties > /opt/teamcity-agent/conf/buildAgent.properties
#   sed -i 's#^workDir=.*#workDir=/teamcity/work#' /opt/teamcity-agent/conf/buildAgent.properties
#   sed -i 's#^tempDir=.*#tempDir=/teamcity/temp#' /opt/teamcity-agent/conf/buildAgent.properties
#   sed -i 's#^systemDir=.*#systemDir=/teamcity/system#' /opt/teamcity-agent/conf/buildAgent.properties

#   echo '' >> /opt/teamcity-agent/conf/buildAgent.properties
#   echo -E "etc.issue=$(cat /etc/issue | tr '\n' ' ')" >> /opt/teamcity-agent/conf/buildAgent.properties
#   chmod ug+x /opt/teamcity-agent/bin/*.sh

#   cat > /etc/systemd/system/teamcity-agent.service <<EOF
# [Unit]
# Description=TeamCity Agent
# After=network.target
# [Service]
# ExecStart=/opt/teamcity-agent/bin/agent.sh run
# Restart=always
# RestartSec=15
# StartLimitInterval=0
# [Install]
# WantedBy=multi-user.target
# EOF

#   chmod 0644 /etc/systemd/system/teamcity-agent.service
#   systemctl enable teamcity-agent

#   wait_for_upgrade(){
#     local max_attempts=10
#     local attempt=1
#     local agent_log="/opt/teamcity-agent/logs/teamcity-agent.log"
#     while [[ "${attempt}" -le "${max_attempts}" ]]; do
#       if [[ -f "${agent_log}" ]]; then
#         if grep -q "Exit for upgrade" "${agent_log}"; then
#           echo "Agent upgrade complete"
#           return 0
#         fi
#       fi
#       echo "Agent upgrade not yet complete"
#       let attempt++
#       sleep 60
#     done
#     echo "Agent upgrade did not complete after ${max_attempts} attempts"
#     return 1
#   }

#   # install stuff from TeamCity server, agent start will handle this.
#   systemctl start teamcity-agent
#   wait_for_upgrade
#   systemctl stop teamcity-agent

#   sed -i "s/name=.*/name=/" /opt/teamcity-agent/conf/buildAgent.properties
#   sed -i "s/authorizationToken=.*/authorizationToken=/" /opt/teamcity-agent/conf/buildAgent.properties
# )}

function moveSymlinkEtcResolvConfScriptToCloudInit {
  echo "Moving symlink-etc-resolv-conf.sh to /var/lib/cloud/scripts/per-boot"
  echo ""
  mv /tmp/symlink-etc-resolv-conf.sh /var/lib/cloud/scripts/per-boot/symlink-etc-resolv-conf.sh
  chmod +x /var/lib/cloud/scripts/per-boot/symlink-etc-resolv-conf.sh
  echo "Moving done"
  echo ""
}

# Depends on installTeamCityAgent
function installMaven {
  curl -0 http://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz | tar xz -C /opt
  echo -n -e "env.MAVEN_HOME_32x=/opt/apache-maven-3.2.5\n\n" >> /opt/teamcity-agent/conf/buildAgent.properties
}

function installVagrant {
  _wget -O /tmp/vagrant.deb https://releases.hashicorp.com/vagrant/1.9.1/vagrant_1.9.1_x86_64.deb
  dpkg -i /tmp/vagrant.deb
  rm /tmp/vagrant.deb
  apt-get -qy install nfs-kernel-server qemu libvirt-bin libvirt-dev
  vagrant plugin install vagrant-libvirt
  vagrant plugin install vagrant-mutate
  echo -n -e "VAGRANT=/usr/bin/vagrant\n" >> /opt/teamcity-agent/conf/buildAgent.properties
}

function installSalt {
  apt-get install -y salt-minion
  sed -i 's/#\?master:.*/master: salt1.vm.ca1.mesosphere.com/' /etc/salt/minion
  systemctl restart salt-minion
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

function chmodCredentialFiles() {

  ownAnd600 /root/.m2/settings-security.xml
  ownAnd600 /root/.sbt

  ownAnd600 /root/.gnupg
  ownAnd600 /root/.gnupg_dcos-cosmos
}

function addTeamcityIamProperty() {

  local role=${TEAMCITY_AGENT_IAM_ROLE:-""}
  if [[ -n ${role} ]]; then
    echo -E "IAM_ROLE=$role" >> /opt/teamcity-agent/conf/buildAgent.properties
  fi

}

function addPythonVersionProperties() {(

  py27=$(/usr/bin/python2.7 --version 2>&1 > /dev/null)
  if [ $? -eq 0 ]; then
    echo -n -e "PYTHON_27=/usr/bin/python2.7\n" >> /opt/teamcity-agent/conf/buildAgent.properties
  fi
  py34=$(/usr/bin/python3.4 --version 2>&1 > /dev/null)
  if [ $? -eq 0 ]; then
    echo -n -e "PYTHON_34=/usr/bin/python3.4\n" >> /opt/teamcity-agent/conf/buildAgent.properties
  fi
  py35=$(/usr/bin/python3.5 --version 2>&1 > /dev/null)
  if [ $? -eq 0 ]; then
    echo -n -e "PYTHON_35=/usr/bin/python3.5\n" >> /opt/teamcity-agent/conf/buildAgent.properties
  fi

)}

function onAWS {
  ([ -f /sys/hypervisor/uuid ] && [ "$(head -c 3 /sys/hypervisor/uuid)" == "ec2" ]) || \
  ([ "$(dmidecode --string system-uuid | head -c 3)" == "EC2" ])
}

function shouldInstallCredentials() {
  ${SHOULD_INSTALL_CREDENTIALS:-false}
}

function main {
  #export DEBIAN_FRONTEND=noninteractive
  env | sort

  # we do that at the very beginning as it is crucial
  onAWS && moveSymlinkEtcResolvConfScriptToCloudInit

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

  installTeamCityAgent

  echo -n -e "GPG2=/usr/bin/gpg2\n" >> /opt/teamcity-agent/conf/buildAgent.properties

  addDocker

  apt-get autoremove -y

  gem update --system 3.0.5 && gem install fpm

  pip3 install --upgrade pip==9.0.3 && pip3 install tox httpie

  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  ./aws/install
  rm -rf ./aws

  installjq
  installOracleJDK8
  installPacker
  apt-get install -y python3.4 python3.4-dev
  apt-get install -y python3.5 python3.5-dev
  installMaven
  shouldInstallCredentials && moveCredentialFilesIntoPlace && chmodCredentialFiles
  addPythonVersionProperties
  addTeamcityIamProperty
  onAWS || installVagrant
  onAWS || installSalt

  echo "cat /opt/teamcity-agent/conf/buildAgent.properties"
  cat /opt/teamcity-agent/conf/buildAgent.properties
}

function ownAnd600() {
  # Own it all
  chown root:root -R "${1}"
  # set directories to 700
  find "${1}" -type d -exec chmod 0700 {} \;
  # set all files to 600
  find "${1}" -type f -exec chmod 0600 {} \;
}

main "$@"