#!/bin/bash
# Performs work on the Raspberry after it starts
K3S_TOKEN=$(</home/pi/.k3s_token)
KUBE_NODE_NAME=$(</home/pi/.k3s_node_name)

if [ ! -f /home/pi/.pi_mark_iptables ]; then
  # Enables legacy ip-tables, required by k3s https://rancher.com/docs/k3s/latest/en/advanced/#enabling-legacy-iptables-on-raspbian-buster
  sudo iptables -F
  sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
  sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
  
  touch /home/pi/.pi_mark_iptables # create a marker on disk, to let us know this step is already done.
  sudo reboot
fi

if ! command -v k3s > /dev/null
then
  # Wait for ntp to sync the time, otherwise curl: (60) SSL certificate problem: certificate is not yet valid
  while [[ $(timedatectl status | grep 'System clock synchronized' | grep -Eo '(yes|no)') = no ]]; do
      sleep 2
  done
  echo "k3s install required"
  curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.220:6443 K3S_TOKEN=$K3S_TOKEN K3S_NODE_NAME="$KUBE_NODE_NAME" sh -s - --with-node-id "$(date +"%s")" --node-label pi-cluster-level="$KUBE_NODE_NAME" > /home/pi/k3s_install.txt
fi