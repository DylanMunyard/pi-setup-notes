# pi-setup-notes
> https://www.raspberrypi.org/documentation/installation/installing-images/linux.md
- Download Raspberry Pi OS Lite https://www.raspberrypi.org/software/operating-systems/
- Run `./install.sh /dev/sda raspios.img`

```
# to find the SD card partition
lsblk -p
/dev/sda           8:0    1  29.7G  0 disk 
└─/dev/sda1        8:1    1  29.7G  0 part
 
# unmount the partition
umount /dev/sda1

# burn the image to the SD Card
sudo dd bs=4M if=2020-12-02-raspios-buster-armhf-lite.img of=/dev/sda conv=fsync 
```

## Enable cgroups
After it's done, add `cgroup_memory=1 cgroup_enable=memory` to /boot/cmdline.txt
https://rancher.com/docs/k3s/latest/en/advanced/#enabling-cgroups-for-raspbian-buster

## Enable ssh
> https://howtoraspberrypi.com/enable-ssh/

`touch ssh /boot`

Use an SSH key to connect to the Pi. 
Generate the key once, and use for all Pis:
- `mkdir ~/pi && ssh-keygen -f ~/pi/pi-key -t rsa`
  
Copy the key to the Pi, and add it to the trusted keys
- `cp ~/pi/pi-key.pub /rootfs/home/pi/pi-key.pub`
- `cp ~/pi/pi-key.pub /rootfs/home/pi/.ssh/authorized_keys`

Connect to the Pi by specifying the key:
- `ssh -i ~/pi/pi-key pi@IP`

Default username and password:
- `pi` / `raspberry`



## Set a static IP
We should only do this on the master node, so that worker node Pis
will discover her. Then from `kubectl` we get query for the node IPs.


Edit `/etc/dhcpcd.conf`:
```
interface eth0
static ip_address=192.168.86.220/24
```