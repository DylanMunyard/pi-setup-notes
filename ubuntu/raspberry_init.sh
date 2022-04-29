#!/bin/bash
# Performs work on the Raspberry after it starts
K3S_TOKEN=$(</home/ubuntu/.k3s_token)
KUBE_NODE_NAME=$(</home/ubuntu/.k3s_node_name)

if ! command -v k3s > /dev/null
then
  # Wait for ntp to sync the time, otherwise curl: (60) SSL certificate problem: certificate is not yet valid
  while [[ $(timedatectl status | grep 'System clock synchronized' | grep -Eo '(yes|no)') = no ]]; do
      sleep 2
  done

  # set the hostname to the node name so we can tell Pis aparent in the network
  sudo hostnamectl set-hostname $KUBE_NODE_NAME

  # bring the network interface up
  sudo ip link set eth0 up
  sudo netplan apply

  # since we created the home folder, it'll be owned by root
  sudo chown -R ubuntu:ubuntu /home/ubuntu
  
  # install nfs-common, required to mount nfs shares
  sudo apt install nfs-common -y

  # vxlan required by k3s https://rancher.com/docs/k3s/latest/en/advanced/#enabling-vxlan-on-ubuntu-21.10+-on-raspberry-pi
  sudo apt install linux-modules-extra-raspi -y
  
  # install nfs-kernel-server, required to host nfs shares
  sudo apt install nfs-kernel-server -y

  if [ -f "/home/ubuntu/.k3s_master" ]; then
    curl -sfL https://get.k3s.io | sh -s - --with-node-id "$(date +"%s")" --node-label k3s-upgrade=true --node-label pi-cluster-level="$KUBE_NODE_NAME" > /home/ubuntu/k3s_install.txt
    # replace the path where the local-path provisioner will create PVs  
    sed -i 's/\/var\/lib\/rancher\/k3s\/storage/\/media\/k8s_store/' /var/lib/rancher/k3s/server/manifests/local-storage.yaml > /var/lib/rancher/k3s/server/manifests/local-storage.yaml
  else
    curl -sfL https://get.k3s.io | sh -s - agent --token "$K3S_TOKEN" --server "https://192.168.86.220:6443"  --node-name "$KUBE_NODE_NAME" --with-node-id "$(date +"%s")" --node-label k3s-upgrade=true --node-label pi-cluster-level="$KUBE_NODE_NAME" > /home/ubuntu/k3s_install.txt
  fi
fi