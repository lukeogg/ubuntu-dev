#!/bin/bash

make install-tools
make install-gojq
cp .local/tools/gojq .local/tools/jq
mkdir artifacts
make configure-ecr-credentials

echo "Make sure to remove configure-ecr-credentials from make target dependencies"
