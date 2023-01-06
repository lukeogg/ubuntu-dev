TARGET_REPO := $(GOPATH)/src/github.com/mesosphere/dkp-insights
TERRAFORM_OPTS := -var owner=$(shell whoami) -auto-approve
EC2_INSTANCE_USER = ubuntu
ifneq ("$(wildcard $(CURDIR)/inventory)","")
EC2_INSTANCE_HOST = $(strip $(shell cat inventory | grep -E "(.*)amazonaws\.com"))
EC2_SSH_KEY = $(shell cat inventory | grep -E ".*\.pem" | cut -d "=" -f 2)
endif
RSYNC_OPTS := -rav --exclude '.idea' --exclude '.local' $(TARGET_REPO) $(EC2_INSTANCE_USER)@$(EC2_INSTANCE_HOST):~/go/src/github.com/mesosphere

check-var:
ifndef EC2_INSTANCE_HOST
$(error EC2_INSTANCE_HOST is not set)
endif
ifndef EC2_SSH_KEY
$(error EC2_SSH_KEY is not set)
endif

.PHONY: sync
sync: check-var
sync:
	ssh-add $(EC2_SSH_KEY)
	# Perform initial sync
	rsync $(RSYNC_OPTS)
	# Watch for changes and sync
	fswatch -r -v $(TARGET_REPO) | xargs -I{} rsync $(RSYNC_OPTS)

.PHONY: connect
connect: check-var
connect:
	ssh -i $(EC2_SSH_KEY) -o "StrictHostKeyChecking=accept-new" $(EC2_INSTANCE_USER)@$(EC2_INSTANCE_HOST)

.PHONY: create
create:
	terraform init
	terraform apply $(TERRAFORM_OPTS)

.PHONY: destroy
destroy:
	terraform destroy $(TERRAFORM_OPTS)

.PHONY: clean
clean:
	rm -rf .terraform* *.pem terraform.tfstate*