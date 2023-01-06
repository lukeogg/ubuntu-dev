#!/bin/bash
set -euox pipefail

export GOPATH="$HOME/go"

export IR=${GOPATH}/src/github.com/mesosphere/dkp-insights
export PATH=${IR}/.local/tools:${PATH}

export BACKEND_KUBECONFIG=${IR}/artifacts/backend.kubeconfig
export MANAGEMENT_KUBECONFIG=${IR}/artifacts/management.kubeconfig
export DAILY_KUBECONFIG=${HOME}/repositories/daily-cluster/dkp-daily.conf

export USE_KIND_CLUSTERS=true
export INSIGHTS_NAMESPACE=kommander

rm -rf artifacts/

# Create Kind cluster
./hack/create-environments/create-environments.sh create-management-cluster

# Create a symlink for the backend cluster config to point to the management cluster
./hack/create-environments/create-environments.sh create-backend-cluster

# Install Kommander
./hack/create-environments/create-environments.sh install-kommander

# Install Insights Snapshot
./hack/create-environments/create-environments.sh install-insights-backend