TARGET_REPO := $(GOPATH)/src/github.com/mesosphere/dkp-insights
TERRAFORM_OPTS := -var owner=$(shell whoami) -auto-approve
EC2_INSTANCE_USER := ubuntu

ifneq ("$(wildcard $(CURDIR)/inventory)","")
EC2_INSTANCE_HOST := $(strip $(shell cat inventory | grep -E "(.*)amazonaws\.com"))
EC2_SSH_KEY := $(shell cat inventory | grep -E ".*\.pem" | cut -d "=" -f 2)
endif

RSYNC_OPTS := -rav --exclude '.idea' --exclude '.local' $(TARGET_REPO) $(EC2_INSTANCE_USER)@$(EC2_INSTANCE_HOST):~/go/src/github.com/mesosphere
SSH_TUNNEL_PORT := 1337

# Start one-way synchronization of the $(TARGET_REPO) to the remote host
.PHONY: sync-repo
sync-repo:
	ssh-add $(EC2_SSH_KEY)
	# Perform initial sync
	rsync $(RSYNC_OPTS)
	# Watch for changes and sync
	fswatch --one-per-batch --recursive --latency 1 $(TARGET_REPO) | xargs -I{} rsync $(RSYNC_OPTS)

# Create SSH tunnel to the remote instance
.PHONY: tunnel
tunnel:
	nc -z localhost $(SSH_TUNNEL_PORT) || ssh -D $(SSH_TUNNEL_PORT) -f -C -q -N $(EC2_INSTANCE_USER)@$(EC2_INSTANCE_HOST)

.PHONY: dashboard
dashboard: tunnel
dashboard:
	@echo Obtaining DKP credentials...
	@ssh $(EC2_INSTANCE_USER)@$(EC2_INSTANCE_HOST) "kubectl -n kommander get secret dkp-credentials \
		-o go-template='{{ \"\n\"}}Username: {{.data.username|base64decode}}{{ \"\n\"}}Password: {{.data.password|base64decode}}{{ \"\n\"}}'"
	@echo "---------------------------------------------------"
	@echo Launching Kommander Dashboard...
	@open $(shell ssh $(EC2_INSTANCE_USER)@$(EC2_INSTANCE_HOST) "kubectl -n kommander get svc kommander-traefik \
		-o go-template='https://{{with index .status.loadBalancer.ingress 0}}{{or .hostname .ip}}{{end}}/dkp/kommander/dashboard{{ \"\n\"}}'")

# Connect to the remote instance
.PHONY: connect
connect:
	ssh -i $(EC2_SSH_KEY) -o "StrictHostKeyChecking=accept-new" -o "ServerAliveInterval=3600" $(EC2_INSTANCE_USER)@$(EC2_INSTANCE_HOST)

# Create an EC2 instance with Terraform
.PHONY: create
create:
	terraform init
	terraform apply $(TERRAFORM_OPTS)

# Destroy an EC2 instance
.PHONY: destroy
destroy:
	terraform destroy $(TERRAFORM_OPTS)

.PHONY: clean
clean:
	rm -rf .terraform* *.pem terraform.tfstate*