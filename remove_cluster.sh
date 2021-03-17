#!/bin/bash

usage() {
    echo "Usage: ./remove_cluster.sh csp_type(aws|gcp|azure)"
    exit 1
}

if [ "$1" == "" ]; then
    usage
fi

CURRENT_DIRECTORY=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

cd $CURRENT_DIRECTORY/terraform/$1
terraform destroy -auto-approve

