#!/bin/bash
# Performs work on the Raspberry after it starts
if ! command -v k3s > /dev/null
then
    echo "k3s install required"
    curl -sfL https://get.k3s.io | K3S_URL=https://kube-master:6443 K3S_TOKEN=$K3S_TOKEN sh - > ~/k3s_install.txt
fi