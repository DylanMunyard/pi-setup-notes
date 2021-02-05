# usage: install.sh /dev/sdx /path/to/raspberrypi.img
# /dev/sdx is the SD card disk
# /path/to/raspberrypi.img is the Raspberry Pi OS image

if [ "$#" -ne 2 ]
then
  printf "Incorrect usage\n"
  printf "./install.sh /dev/sd_card_partition /path/to/raspberrypi.img\n"
  echo "e.g. ./install /dev/sda ~/Downloads/raspios.img"
  exit 1  
fi

echo "Write the Raspberry Pi OS to the SD Card"
sudo dd bs=4M if="$2" of="$1" status=progress conv=fsync
echo "Done - Write the Raspberry Pi OS to the SD Card"

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

# enable cgroups
echo "Enable cgroups"
CMD_LINE=$(sudo cat "$BOOT_FOLDER/cmdline.txt")
CMD_LINE="$CMD_LINE cgroup_memory=1 cgroup_enable=memory"
echo "$CMD_LINE" | sudo tee "$BOOT_FOLDER/cmdline.txt"

# enable SSH
echo "Enable ssh"
touch "$BOOT_FOLDER/ssh"
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