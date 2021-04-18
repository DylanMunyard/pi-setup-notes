# pi-setup-notes
See [Equipment](EQUIPMENT.md) for what the end result looks like. \
See [Edge instructions](EDGE.md) for how to configure external access to it.

> https://www.raspberrypi.org/documentation/installation/installing-images/linux.md
- Download Ubuntu Server for ARM, https://ubuntu.com/download/server/arm
- Insert the SD card, find it's partition name from `lsblk -p`, e.g. \dev\sda, dev\sdb etc
- Install everything using [install.sh](ubuntu/install.sh).

| Option |  Value  |
|:-----:|:--------|
| /dev/sdcard | The root partition name of the SD card. How-to find it is listed below. |
| server_img.img  | The OS image to install |
| server_token | The k3s server token, from the master: `/var/lib/rancher/k3s/server/node-token` |
| node_name | The node name to give the Raspberry Pi in the cluster. I describe the level the Pi is installed on, e.g. `level4` |
| wifi_password | The Wifi password |

## Find the SD card partion name
```
# to find the SD card partition
lsblk -p
/dev/sda           8:0    1  29.7G  0 disk 
└─/dev/sda1        8:1    1  29.7G  0 part
 
# unmount the partition
umount /dev/sda1 
```

# What install.sh does

### Enable cgroups
Add `cgroup_memory=1 cgroup_enable=memory` to /boot/cmdline.txt
https://rancher.com/docs/k3s/latest/en/advanced/#enabling-cgroups-for-raspbian-buster

### Enable ssh
> https://howtoraspberrypi.com/enable-ssh/

`touch ssh /boot`

Default username and password:
- `pi` / `raspberry` for Raspbian
- `ubuntu` / `ubuntu` for Ubuntu Server

### Configure a trusted SSH key/pair
Do this from your laptop:
- `mkdir ~/pi && ssh-keygen -f ~/pi/pi-key -t rsa`

Trust the key on the Pi
- `cp ~/pi/pi-key.pub /rootfs/home/pi/pi-key.pub`
- `cp ~/pi/pi-key.pub /rootfs/home/pi/.ssh/authorized_keys`

Connect to the Pi by specifying the key:
- `ssh -i ~/pi/pi-key pi@IP`

### Configure a start up script to install k3s
> https://www.2daygeek.com/enable-disable-services-on-boot-linux-chkconfig-systemctl-command/

- Copy [init_pi.service](./ubuntu/init_pi.service) to `/rootfs/etc/systemd/system/init_pi.service`
- To make it run automatically, create a symlink to it in `/etc/systemd/system/multi-user.target.wants/init_pi.service`
- It simply calls [raspberry_init.sh](ubuntu/raspberry_init.sh) to do the work.

### Set a static IP - master node only
Raspbian OS:
Edit `/etc/dhcpcd.conf`:
```
interface eth0
static ip_address=192.168.86.220/24
static routers=192.168.86.1
static domain_name_servers=192.168.86.1
```

Ubuntu Server:
https://kirelos.com/how-to-configure-static-ip-address-on-ubuntu-20-04/

### Set the persistent volume folder
Start the k3s server with `--default-local-storage-path /media/k8s_store`.

I found this didn't work if I changed it on a running server.  So SSH onto the master and patch the local-storage manifest. \
k3s is built with support to automatically apply changes to the manifests folder:

```bash
sed -i 's/\/var\/lib\/rancher\/k3s\/storage/\/media\/k8s_store/' /var/lib/rancher/k3s/server/manifests/local-storage.yaml > /var/lib/rancher/k3s/server/manifests/local-storage.yaml
```

__Note__, patching the manifest is taken care of for new master nodes in
the [init script](ubuntu/raspberry_init.sh).

# Enable automatic k3s upgrades
`system-upgrade-controller` has been installed from https://github.com/rancher/system-upgrade-controller.

To upgrade the cluster, deploy a `Plan` https://github.com/rancher/system-upgrade-controller/blob/master/examples/k3s-upgrade.yaml and
set the `version: v1.18.8+k3s1` from https://github.com/k3s-io/k3s/releases.

The nodes must have the `k3s-upgrade=true` label:
`kubectl label node node1 node2 node3 k3s-upgrade=true`

# Attaching storage for persistent workoads
Using a [4TB Western Digital Passport](https://products.wdc.com/library/AAG/ENG/4078-705155.pdf). 
Find it's UUID with `blkid` \
Add it to `/etc/fstab` so it auto-mounts after restart. 
```bash
sudo nano /etc/fstab
UUID=5f88bef3-9f95-4c12-b621-c51859200da7 /media/k8s_store	auto rw,sync,user 0 0
```
## Export PVs as NFS shares
A persistent volume will create itself under /media_k8s_store. 
- After it is created create a sym-link to it: `sudo ln -s <path_to_pv> /media/<alias>`
- Then export it via NFS so it can be mounted by other hosts. E.g. the Emby media folder can be mounted by my laptop. 

```bash
sudo apt install nfs-common -y
sudo apt nfs-kernel-server -y
chmod a+rwxt /media/<alias>
sudo groupadd -g 8888 nfs
sudo useradd -g nfs nfs -u 8888
sudo chown 8888:8888 -R /media/<alias>
# automatically export the NFS share at boot
sudo nano /etc/exports
/media/<alias> 192.168.86.0/24(rw,no_subtree_check,all_squash,anonuid=8888,anongid=8888)
# reload exports without reboot
sudo exportfs -r
```

Add a k8s label to the Pi node:
```bash
kubectl label nodes level3-2a7ff144 pi.attached.storage/exists=true
```

## Network storage
Right now the Pis use either attached physical storage or temporary pod storage. \
But I went through a heap of trouble to get NFS working, only to discover performance
issues and application errors. I documented what I got working here:
- [NFS](NFS.md)

## k3s agent options
`curl -sfL https://get.k3s.io | K3S_URL=https://192.168.86.220:6443 K3S_TOKEN=$K3S_TOKEN K3S_NODE_NAME="$KUBE_NODE_NAME" sh -s - --with-node-id "$(date +"%s")" --node-label pi-cluster-level="$KUBE_NODE_NAME" > /home/pi/k3s_install.txt`

| Option |  Value  | Description |
|:-----|--------:|:------|
| K3S_TOKEN environment variable  | Taken from `/var/lib/rancher/k3s/server/node-token` on the master node. | Authentication token for agent->server. |
| K3S_URL environment variable  |  https://192.168.86.220:6443 | Important to use the IP, and not an alias. |
| K3S_NODE_NAME | The name of the node as it appears in `kubectl get nodes` | Specify the level in the cluster. |
| --with-node-id option | ` "$(date +"%s")"` | Specifies a unique suffix for the node name. This is necessary to avoid conflicts with previous attempts to join the cluster under the same node name. It causes authentication issues if you try to re-use the name. |
| --node-label | `pi-cluster-level="$KUBE_NODE_NAME"` | Add this is a selectable node label. Will come in handy later when deploying to specific Pis |

# Troubleshooting
The default password for Ubuntu is `ubuntu`

If the mount persists even after removing SD, force unmount: \
`cat /proc/mounts` to list them
`sudo umount -f /dev/sda1` will force unmount it.

Find the Pi IP using nmap:
> https://www.howtogeek.com/423709/how-to-see-all-devices-on-your-network-with-nmap-on-linux/

`sudo nmap -sn 192.168.86.0/24`

## Shutdown Pi
Shut down the Pi
`sudo shutdown now` \
Restart `sudo shutdown -r`
