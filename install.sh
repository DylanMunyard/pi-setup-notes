#!/bin/bash
# usage: install.sh /dev/sdx /path/to/raspberrypi.img server_token
# /dev/sdx is the SD card disk
# /path/to/raspberrypi.img is the Raspberry Pi OS image
# server_token taken from /var/lib/rancher/k3s/server/node-token on kube-master

if [ "$#" -ne 3 ]
then
  printf "Incorrect usage\n"
  printf "./install.sh /dev/sd_card_partition /path/to/raspberrypi.img k3s_token\n"
  echo "e.g. ./install /dev/sda ~/Downloads/raspios.img abcd123"
  exit 1  
fi

# Write the Raspberry OS to the SD card
echo "Write the Raspberry Pi OS to the SD Card"
sudo dd bs=4M if="$2" of="$1" status=progress conv=fsync
echo "Done - Write the Raspberry Pi OS to the SD Card"

# mount the partitions
MNT_FOLDER="/media/$(hostname)"
BOOT_FOLDER="$MNT_FOLDER/pi_boot"
ROOT_FOLDER="$MNT_FOLDER/pi_root"
if [ -d "$BOOT_FOLDER" ]; then
  echo "Removing existing boot mount folder $BOOT_FOLDER"
  rm -rf "$BOOT_FOLDER"
fi
if [ -d "$ROOT_FOLDER" ]; then
  echo "Removing existing root mount folder $ROOT_FOLDER"
  rm -rf "$ROOT_FOLDER"
fi

echo "Mounting boot partition@$BOOT_FOLDER"
mkdir "$BOOT_FOLDER" && sudo mount /dev/sda1 "$BOOT_FOLDER"

echo "Mounting root partition@$ROOT_FOLDER"
mkdir "$ROOT_FOLDER" && sudo mount /dev/sda2 "$ROOT_FOLDER"

echo "Copy raspberry init scripts"
sudo cp raspberry_run_init.service "$ROOT_FOLDER/etc/systemd"
sudo cp raspberry_init.sh "$ROOT_FOLDER/usr/local/bin"

# enable kernel parameters
echo "Enable kernel parameters"
CMD_LINE=$(sudo cat "$BOOT_FOLDER/cmdline.txt")
CMD_LINE="$CMD_LINE cgroup_memory=1 cgroup_enable=memory"
echo "$CMD_LINE" | sudo tee "$BOOT_FOLDER/cmdline.txt"

# enable SSH
echo "Enable ssh"
sudo touch "$BOOT_FOLDER/ssh"
if [ ! -f "$ROOT_FOLDER/home/pi/pi-key.pub" ]; then
  echo "Copying ssh key"
  sudo cp ~/pi/pi-key.pub "$ROOT_FOLDER/home/pi/pi-key.pub"
fi

if [ ! -f "$ROOT_FOLDER/home/pi/.ssh" ]
then
  sudo mkdir "$ROOT_FOLDER/home/pi/.ssh"  
fi
echo "Trust ssh key"
sudo cp ~/pi/pi-key.pub "$ROOT_FOLDER/home/pi/.ssh/authorized_keys" 

# set up a hosts entry for kube-master IP
printf "%s\t%s" "192.168.86.220" "kube-master" | sudo tee -a "$ROOT_FOLDER/etc/hosts"

# set up k3s_token environment variable
printf "\n%s=\"%s\"\n" "K3S_TOKEN" "$3" | sudo tee -a "$ROOT_FOLDER/home/pi/.profile"