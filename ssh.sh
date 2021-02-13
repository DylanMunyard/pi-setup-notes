#!/bin/bash
# opens an SSH session to the Pi
if [ "$#" -ne 1 ]; then
  echo "Pass the level name of the Pi you want to connect: .\ssh.sh level3"
  exit  
fi

pi_ip=$(kubectl get nodes -l "pi-cluster-level=$1" -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')
if [ -z "$pi_ip" ]; then
  echo "There is no pi-cluster-level=$1"
  exit 1
fi

ssh -i ~/pi/pi-key "pi@$pi_ip"