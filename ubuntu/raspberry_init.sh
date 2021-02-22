#!/bin/bash
# Performs work on the Raspberry after it starts
K3S_TOKEN=$(</home/ubuntu/.k3s_token)
KUBE_NODE_NAME=$(</home/ubuntu/.k3s_node_name)

if ! command -v k3s > /dev/null
then
  # since we created the home folder, it'll be owned by root
  sudo chown -R ubuntu:ubuntu /home/ubuntu
  
  # install nfs-common, required to mount nfs shares
  sudo apt install nfs-common -y
  
  # install nfs-kernel-server, required to host nfs shares
  sudo apt install nfs-kernel-server -y
  
  # Wait for ntp to sync the time, otherwise curl: (60) SSL certificate problem: certificate is not yet valid
  while [[ $(timedatectl status | grep 'System clock synchronized' | grep -Eo '(yes|no)') = no ]]; do
      sleep 2
  done
  if [ -f "/home/ubuntu/.k3s_master" ]; then
    curl -sfL https://get.k3s.io | sh -s - --with-node-id "$(date +"%s")" --default-local-storage-path /media/k8s_store --node-label pi-cluster-level="$KUBE_NODE_NAME" > /home/ubuntu/k3s_install.txt
    # replace the path where the local-path provisioner will create PVs  
    sed -i 's/\/var\/lib\/rancher\/k3s\/storage/\/media\/k8s_store/' /var/lib/rancher/k3s/server/manifests/local-storage.yaml > /var/lib/rancher/k3s/server/manifests/local-storage.yaml
  else
    curl -sfL https://get.k3s.io | K3S_URL=https://192.168.86.220:6443 K3S_TOKEN=$K3S_TOKEN K3S_NODE_NAME="$KUBE_NODE_NAME" sh -s - --with-node-id "$(date +"%s")" --node-label pi-cluster-level="$KUBE_NODE_NAME" > /home/ubuntu/k3s_install.txt
  fi
fi