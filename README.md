# pi-setup-notes
> https://www.raspberrypi.org/documentation/installation/installing-images/linux.md
- Download Raspberry Pi OS Lite https://www.raspberrypi.org/software/operating-systems/
- Insert the SD cart, then run [install.sh /dev/sdcard raspios.img server_token node_name](install.sh).

| Option |  Value  |
|:-----:|:--------|
| /dev/sdcard | The root partition name of the SD card. How-to find it is listed below. |
| raspios.img  | Path to the Raspberry Pi OS image |
| server_token | The k3s server token, obtained from `/var/lib/rancher/k3s/server/node-token` on the master node |
| node_name | The node name to give the Raspberry Pi in the cluster. I describe the level the Pi is installed on, e.g. `level4` |

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

# What install.sh does



## Enable cgroups
After it's done, add `cgroup_memory=1 cgroup_enable=memory` to /boot/cmdline.txt
https://rancher.com/docs/k3s/latest/en/advanced/#enabling-cgroups-for-raspbian-buster

## Add k3s server to hosts
`printf "%s\t%s" "192.168.86.220" "kube-master.local" | sudo tee -a "$ROOT_FOLDER/etc/hosts"`

Found that it has to have .local suffix otherwise k3s agent won't be able
to resolve kube-master. If the hosts name doesn't work, just use the IP.

## Enable ssh
> https://howtoraspberrypi.com/enable-ssh/

`touch ssh /boot`

Default username and password:
- `pi` / `raspberry`

## Authenticate ssh with key
### Generate the ssh key once
Use an SSH key to connect to the Pi. 
Generate the key once, and use for all Pis:
- `mkdir ~/pi && ssh-keygen -f ~/pi/pi-key -t rsa`
  
### Copy ssh key to Pi
Copy the key to the Pi, and add it to the trusted keys
- `cp ~/pi/pi-key.pub /rootfs/home/pi/pi-key.pub`
- `cp ~/pi/pi-key.pub /rootfs/home/pi/.ssh/authorized_keys`

Connect to the Pi by specifying the key:
- `ssh -i ~/pi/pi-key pi@IP`

## Create init script service
> https://www.2daygeek.com/enable-disable-services-on-boot-linux-chkconfig-systemctl-command/

Create a service that will call a bash script to install k3s
- Copy [init_pi.service](./init_pi.service) following to `/rootfs/etc/systemd/system/init_pi.service`
- To make it run automatically, create a symlink to it in `/etc/systemd/system/multi-user.target.wants/init_pi.service` 
- It simply calls [raspberry_init.sh](raspberry_init.sh) to do the work.

## k3s agent options
`curl -sfL https://get.k3s.io | K3S_URL=https://192.168.86.220:6443 K3S_TOKEN=$K3S_TOKEN K3S_NODE_NAME="$KUBE_NODE_NAME" sh -s - --with-node-id "$(date +"%s")" --node-label pi-cluster-level="$KUBE_NODE_NAME" > /home/pi/k3s_install.txt`

| Option |  Value  | Description |
|:-----|--------:|:------|
| K3S_TOKEN environment variable  | Taken from `/var/lib/rancher/k3s/server/node-token` on the master node. | Authentication token for agent->server. |
| K3S_URL environment variable  |  https://192.168.86.220:6443 | Important to use the IP, and not an alias. |
| K3S_NODE_NAME | The name of the node as it appears in `kubectl get nodes` | Specify the level in the cluster. |
| --with-node-id option | ` "$(date +"%s")"` | Specifies a unique suffix for the node name. This is necessary to avoid conflicts with previous attempts to join the cluster under the same node name. It causes authentication issues if you try to re-use the name. |
| --node-label | `pi-cluster-level="$KUBE_NODE_NAME"` | Add this is a selectable node label. Will come in handy later when deploying to specific Pis |  


## Set a static IP - master node only

Edit `/etc/dhcpcd.conf`:
```
interface eth0
static ip_address=192.168.86.220/24
static routers=192.168.86.1
static domain_name_servers=192.168.86.1
```

# Troubleshooting
If the mount persists even after removing SD, force unmount: \
`cat /proc/mounts` to list them
`sudo umount -f /dev/sda1` will force unmount it.

Find the Pi IP using nmap:
> https://www.howtogeek.com/423709/how-to-see-all-devices-on-your-network-with-nmap-on-linux/

`sudo nmap -sn 192.168.86.0/24`