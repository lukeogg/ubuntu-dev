# Provision an ubuntu machine for dev and testing
#
# requires: terraform 0.13.5

SELF_DIR := $(ROOT_DIR)

.PHONY: create
create:
    teraform apply

.PHONY: destroy
destroy:
    teraform destroy