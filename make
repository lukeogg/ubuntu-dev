# Provision an ubuntu machine for dev and testing
#
# requires: terraform 0.13.5

SELF_DIR := $(ROOT_DIR)/airgapped

.airgapped/konvoy/.init:
	mkdir -p $(AIRGAPPED_ARTIFACTS_DIR)/konvoy
	pushd $(AIRGAPPED_ARTIFACTS_DIR)
	# Copying Ansible playbooks from Konvoy repo
	mkdir -p extras/ansible
	cp -a $(SELF_DIR)/vendor_playbooks/* extras/ansible

	# Generating ssh keys and templating cluster.yaml with keys and owner/expiration"
	cp $(SELF_DIR)/cluster.airgapped.yaml cluster.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy-config.sh cluster.yaml
	popd
	echo >$@

#################
# Step 1
#################
.airgapped/provision: .airgapped/konvoy/.init
.airgapped/provision: export WORKER_NODE_COUNT=7
.airgapped/provision:
	pushd $(AIRGAPPED_ARTIFACTS_DIR)
	# Adding private key to SSH agent and comment out privateKeyFile from the cluster.yaml"
	ssh-add $$($(KUDO_TOOLS_DIR)/vendor/yq.sh r cluster.yaml 'spec.sshCredentials.privateKeyFile')
	#sed -i'.bak' 's|privateKeyFile|# privateKeyFile|' cluster.yaml

	# Provisioning the hardware (only)
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh provision -y
	popd
	echo >$@

.airgapped/bastion: .airgapped/provision
.airgapped/bastion:
	pushd $(AIRGAPPED_ARTIFACTS_DIR)
	cp $(SELF_DIR)/bastion.yaml extras/ansible/bastion.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/bastion.yaml
	popd
	echo >$@

#################
# Step 2
#################
.airgapped/download-bundles: .airgapped/bastion
.airgapped/download-bundles:
	pushd $(AIRGAPPED_ARTIFACTS_DIR)
	cp $(SELF_DIR)/konvoy_bundle.yaml extras/ansible/konvoy_bundle.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/konvoy_bundle.yaml

	# Kaptain bundle handling is implemented as a separate playbook to ease syncing with the docs
	cp $(SELF_DIR)/kaptain_bundle.yaml extras/ansible/kaptain_bundle.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/kaptain_bundle.yaml
	popd
	echo > $@

.airgapped/state.json: .airgapped/provision
.airgapped/state.json:
	pushd "$(AIRGAPPED_ARTIFACTS_DIR)/state"
	# reinitialize plugins to avoid compatibility issues
	rm -rf .terraform
	terraform init "$(KONVOY_DIR)/providers/aws"

	terraform show -json > "$(AIRGAPPED_ARTIFACTS_DIR)/state.json"
	popd

.airgapped/egress_sg: .airgapped/state.json
.airgapped/egress_sg:
	$(KUDO_TOOLS_DIR)/vendor/jq.sh '.values.root_module.resources[] | select(.address == "aws_security_group.konvoy_egress[0]") | .values.id' .airgapped/state.json | tr -d '\"' > $@

.airgapped/public_subnet_cidr: .airgapped/state.json
.airgapped/public_subnet_cidr:
	$(KUDO_TOOLS_DIR)/vendor/jq.sh '.values.root_module.resources[] | select(.address == "aws_subnet.konvoy_public[0]") | .values.cidr_block' .airgapped/state.json | tr -d '\"' > $@

.airgapped/control_plane_cidr: .airgapped/state.json
.airgapped/control_plane_cidr:
	$(KUDO_TOOLS_DIR)/vendor/jq.sh '.values.root_module.resources[] | select(.address == "aws_subnet.konvoy_control_plane[0]") | .values.cidr_block' .airgapped/state.json | tr -d '\"' > $@

.airgapped/configure-network: .airgapped/download-bundles
.airgapped/configure-network: .airgapped/public_subnet_cidr
.airgapped/configure-network: .airgapped/control_plane_cidr
.airgapped/configure-network: .airgapped/egress_sg
.airgapped/configure-network:
	aws --region us-west-2 ec2 authorize-security-group-egress --group-id $(shell cat .airgapped/egress_sg) \
		--ip-permissions IpProtocol=-1,FromPort=0,ToPort=0,IpRanges="[{CidrIp=$(shell cat .airgapped/public_subnet_cidr)},{CidrIp=$(shell cat .airgapped/control_plane_cidr)}]"

	aws --region us-west-2 ec2 authorize-security-group-egress --group-id $(shell cat .airgapped/egress_sg) \
		--ip-permissions IpProtocol=tcp,FromPort=6443,ToPort=6443,IpRanges="[{CidrIp=0.0.0.0/0}]"

	aws --region us-west-2 ec2 revoke-security-group-egress --group-id $(shell cat .airgapped/egress_sg) \
		--ip-permissions IpProtocol=-1,FromPort=0,ToPort=0,IpRanges="[{CidrIp=0.0.0.0/0}]"

	aws --region us-west-2 ec2 describe-security-groups --group-ids $(shell cat .airgapped/egress_sg)
	echo > $@

.airgapped/enable-egress: .airgapped/configure-network
.airgapped/enable-egress:
	aws --region us-west-2 ec2 authorize-security-group-egress --group-id $(shell cat .airgapped/egress_sg) \
		--ip-permissions IpProtocol=-1,FromPort=0,ToPort=0,IpRanges="[{CidrIp=0.0.0.0/0}]"

.airgapped/disable-egress: .airgapped/configure-network
.airgapped/disable-egress:
	aws --region us-west-2 ec2 revoke-security-group-egress --group-id $(shell cat .airgapped/egress_sg) \
		--ip-permissions IpProtocol=-1,FromPort=0,ToPort=0,IpRanges="[{CidrIp=0.0.0.0/0}]"

.airgapped/bastion_ip: .airgapped/bastion
.airgapped/bastion_ip:
	$(KUDO_TOOLS_DIR)/vendor/yq.sh r $(AIRGAPPED_ARTIFACTS_DIR)/inventory.yaml 'bastion.hosts' | egrep "^[0-9]+" | tr -d ':' > $@

.airgapped/bastion_host: .airgapped/bastion
.airgapped/bastion_host:
	$(KUDO_TOOLS_DIR)/vendor/yq.sh r $(AIRGAPPED_ARTIFACTS_DIR)/inventory.yaml 'bastion.hosts[*].ansible_host' > $@

.airgapped/run-playbooks: .airgapped/configure-network
.airgapped/run-playbooks: .airgapped/bastion_ip
.airgapped/run-playbooks: .airgapped/bastion_host
.airgapped/run-playbooks:
	pushd $(AIRGAPPED_ARTIFACTS_DIR)
	sed -i'.bak' 's|BASTION_IP_TEMPLATE|$(shell cat .airgapped/bastion_ip)|' cluster.yaml
	sed -i'.bak' 's|# privateKeyFile|privateKeyFile|' cluster.yaml

	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/verify-no-internet.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/configure-docker.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/start-docker-registry.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/configure-yum.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/copy-cluster-files.yaml

	cp $(SELF_DIR)/prepare_install.yaml extras/ansible/prepare_install.yaml
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh run playbook -y extras/ansible/prepare_install.yaml

	popd
	echo > $@

#################
# Step 3
#################
.airgapped/install-konvoy: .airgapped/run-playbooks
.airgapped/install-konvoy:
	pushd $(AIRGAPPED_ARTIFACTS_DIR)
	# there were complications running remote Konvoy commands using local 'konvoy run playbook'
	# so using ssh with agent forwarding until a better alternative is in place
	ssh -o StrictHostKeyChecking=accept-new -A centos@$(shell cat .airgapped/bastion_host) "cd /home/centos/konvoy/konvoy_$(KONVOY_VERSION) && ./konvoy run playbook -y copy-ca-to-nodes.yaml"
	ssh -o StrictHostKeyChecking=accept-new -A centos@$(shell cat .airgapped/bastion_host) "cd /home/centos/konvoy/konvoy_$(KONVOY_VERSION) && ./konvoy deploy kubernetes -y"
	ssh -o StrictHostKeyChecking=accept-new -A centos@$(shell cat .airgapped/bastion_host) "cd /home/centos/konvoy/konvoy_$(KONVOY_VERSION) && ./konvoy deploy -y"
	popd
	echo > $@

.airgapped/kubectl-kudo: .airgapped/install-konvoy
.airgapped/kubectl-kudo:
	curl -L -o $@ https://github.com/kudobuilder/kudo/releases/download/v0.19.0/kubectl-kudo_0.19.0_linux_x86_64

.airgapped/kudo-kaptain.tgz: .airgapped/install-konvoy
.airgapped/kudo-kaptain.tgz:
	# This appears to no longer work... pull from github instead?
	# gsutil cp $(KUDO_KUBEFLOW_RELEASE_BUCKET)/kubeflow-$(KUBEFLOW_RELEASE_VERSION)_$(KUDO_KUBEFLOW_RELEASE_VERSION).tgz $@


#################
# Step 4
#################
.airgapped/install-kaptain: .airgapped/kubectl-kudo
.airgapped/install-kaptain: .airgapped/kudo-kaptain.tgz
.airgapped/install-kaptain:
	# TODO (akirillov): move KUDO install to Ansible playbook
	scp -o StrictHostKeyChecking=accept-new .airgapped/kubectl-kudo centos@$(shell cat .airgapped/bastion_host):/home/centos/konvoy/konvoy_$(KONVOY_VERSION)/kubectl-kudo
	ssh -o StrictHostKeyChecking=accept-new -A centos@$(shell cat .airgapped/bastion_host) "sudo chmod +x /home/centos/konvoy/konvoy_$(KONVOY_VERSION)/kubectl-kudo && sudo mv /home/centos/konvoy/konvoy_$(KONVOY_VERSION)/kubectl-kudo /usr/bin/kubectl-kudo"
	scp -o StrictHostKeyChecking=accept-new .airgapped/kudo-kaptain.tgz centos@$(shell cat .airgapped/bastion_host):/home/centos/konvoy/konvoy_$(KONVOY_VERSION)/kudo-kaptain.tgz
	ssh -o StrictHostKeyChecking=accept-new -A centos@$(shell cat .airgapped/bastion_host) "cd /home/centos/konvoy/konvoy_$(KONVOY_VERSION) && kubectl kudo --kubeconfig=/home/centos/konvoy/konvoy_$(KONVOY_VERSION)/admin.conf init --wait"
	ssh -o StrictHostKeyChecking=accept-new -A centos@$(shell cat .airgapped/bastion_host) "cd /home/centos/konvoy/konvoy_$(KONVOY_VERSION) && kubectl kudo --kubeconfig=/home/centos/konvoy/konvoy_$(KONVOY_VERSION)/admin.conf \
	install ./kudo-kaptain.tgz --instance kaptain -p kubeflowIngressGatewayServiceAnnotations='{\"service.beta.kubernetes.io/aws-load-balancer-internal\": \"true\"}' --namespace kubeflow --create-namespace"
	echo > $@

.PHONY: .airgapped/destroy
.airgapped/destroy:
	pushd $(AIRGAPPED_ARTIFACTS_DIR)
	$(KUDO_TOOLS_DIR)/vendor/konvoy.sh down -y
	popd
