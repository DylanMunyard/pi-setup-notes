#!/bin/bash
# usage: install.sh /dev/sdx /path/to/raspberrypi.img server_token node_name wifi_password
# /dev/sdx is the SD card disk
# /path/to/raspberrypi.img is the Raspberry Pi OS image
# server_token taken from /var/lib/rancher/k3s/server/node-token on kube-master
# node_name is the node name
# wifi_password connects the Pi to the wifi
# if node_name is master, it will get a static IP

# Requires xz-utils:
# sudo apt-get install xz-utils

Device=$1
Image=$2
Token=$3
NodeName=$4
WifiPassword=$5

if [ "$#" -ne 5 ]
then
  printf "Incorrect usage\n"
  printf "./install.sh /dev/sd_card_partition /path/to/raspberrypi.img k3s_token node_name wifi_pasword\n"
  echo "e.g. ./install /dev/sda ~/Downloads/raspios.img ef1cff level4 lorem_ipsum"
  exit 1  
fi

# Write the Raspberry OS to the SD card
echo "Write the Raspberry Pi OS to the SD Card"
xzcat "$Image" | sudo dd bs=32M of="$Device" status=progress conv=fsync
echo "Done - Write the Raspberry Pi OS to the SD Card"

# mount the partitions
MNT_FOLDER="/media/$(hostname)"
BOOT_FOLDER="$MNT_FOLDER/pi_boot"
ROOT_FOLDER="$MNT_FOLDER/pi_root"

echo "Mounting boot partition ${Device}1$BOOT_FOLDER"
mkdir -p "$BOOT_FOLDER" && sudo mount "${Device}1" "$BOOT_FOLDER"

echo "Mounting root partition ${Device}2$ROOT_FOLDER"
mkdir -p "$ROOT_FOLDER" && sudo mount "${Device}2" "$ROOT_FOLDER"

# enable kernel parameters
echo "Enable kernel parameters"
CMD_LINE=$(sudo cat "$BOOT_FOLDER/cmdline.txt")
CMD_LINE="$CMD_LINE cgroup_memory=1 cgroup_enable=memory"
echo "$CMD_LINE" | sudo tee "$BOOT_FOLDER/cmdline.txt"

# enable SSH
echo "Enable ssh"
sudo touch "$BOOT_FOLDER/ssh"
echo "Creating ubuntu user folder $ROOT_FOLDER/home/ubuntu"
sudo mkdir -p "$ROOT_FOLDER/home/ubuntu/.ssh"
echo "Trust ssh key"
sudo cp ~/.ssh/pi.pub "$ROOT_FOLDER/home/ubuntu/.ssh/authorized_keys"

# Configure Pi init service
echo "Copy raspberry init scripts"
if [ ! -f "$ROOT_FOLDER/etc/systemd/system/init_pi.service" ]
then
  sudo cp init_pi.service "$ROOT_FOLDER/etc/systemd/system"
  sudo ln -s ../init_pi.service "$ROOT_FOLDER/etc/systemd/system/multi-user.target.wants/init_pi.service"
  sudo cp raspberry_init.sh "$ROOT_FOLDER/usr/local/bin"
  sudo chmod +x "$ROOT_FOLDER/usr/local/bin/raspberry_init.sh"  
fi

# set up the master server IP address variable
printf "%s\t%s" "192.168.1.220" "kube-master.local" | sudo tee -a "$ROOT_FOLDER/etc/hosts"

# set up k3s server options
printf "%s" "$Token" | sudo tee -a "$ROOT_FOLDER/home/ubuntu/.k3s_token"
printf "%s" "$NodeName" | sudo tee -a "$ROOT_FOLDER/home/ubuntu/.k3s_node_name"

if [ "$NodeName" == "master" ]; then  
  # mark as master
  printf "%s" "$NodeName" | sudo tee -a "$ROOT_FOLDER/home/ubuntu/.k3s_master"
fi

sudo cp 01-netcfg.yaml "$ROOT_FOLDER/etc/netplan"
sudo cp 99-disable-network-config.cfg "$ROOT_FOLDER/etc/cloud"
sudo sed -i 's/wifi_password/'$WifiPassword'/' "$ROOT_FOLDER/etc/netplan/01-netcfg.yaml"

# create a path on the Pi where local storage will be written to
echo "Creating local-path storage location $ROOT_FOLDER/media/k8s_store"
sudo mkdir -p "$ROOT_FOLDER/media/k8s_store"