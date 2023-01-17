#!/bin/bash

make kind-create-dev-cluster
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.yaml 1>&2
./hack/create-environments/create-environments.sh install-metallb
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | kubectl apply -f - -n kube-system && \
kubectl apply --server-side -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml && \
kubectl wait --for=condition=Available deployments -n metallb-system --all --timeout=5m
kubectl apply --server-side -f artifacts/metallb-config.yaml
make kind-install-kommander
kubectl delete helmrelease dkp-insights-management -n kommander
