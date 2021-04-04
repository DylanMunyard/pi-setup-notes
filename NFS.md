# NFS
> I tried this, but had heaps of locking issues on the NFS, which apparently it's known for.
> 
> Anyway here are the notes for setting up NFS.

For read and write intensive containers, like mysql, it's not
recommended to use NFS. Instead it should use directly attached
storage.

Seems to be a locking issue, where it can't obtain one. Apparently
a well known NFS issue.

Plex media service Docker page says to avoid using NFS due to locking issues.

### Install NFS utils
```bash
sudo apt install nfs-common -y
sudo apt nfs-kernel-server -y
```
`nfs-common` is needed to mount NFS exports. \
`nfs-kernel-server` is needed to host NFS exports. Used by the Pis
that have attached storage.

### Export the NFS Share
To export an NFS share create a folder under /export
```bash
# create the NFS folder
sudo mkdir /export
chmod a+rwxt /export
mkdir /export/nfs

# for the Raspberry Pi running emby I created a sym-link instead:
sudo ln -s <path_to_pv> /media/torrents

# create a Kubernetes group that all containers will run as
sudo groupadd -g 8888 nfs
# add a Kubernetes user to the group, containers will run as this user
sudo useradd -g nfs nfs -u 8888
sudo chown 8888:8888 -R <NFS folder>
# automatically export the NFS share at boot
sudo nano /etc/exports
<NFS folder> 192.168.86.0/24(rw,no_subtree_check,all_squash,anonuid=1001,anongid=8888)
# reload exports without reboot
sudo exportfs -r
```

From another host, to mount the NFS:
```bash
mkdir ~/nfs
sudo mount -t nfs -vvvv 192.168.86.29:/<NFS folder> /home/dylan/nfs

# and to unmount
sudo umount -f -l nfs
```

To automount it
```bash
sudo nano /etc/fstab
192.168.86.79:/192.168.86.29:/<NFS folder> /home/dylan/nfs nfs defaults 0 0
```

### Optional
Then create a 'bind' mount at `/export/nfs` for the partition. \
The point of creating `/export/nfs` is that you have a separate folder to
configure permissions and access from NFS mounts, separate to the physical
partition.

```bash
# to get the partition's UUID:
blkid
#> /dev/nvme0n1p6: UUID="efabbd25-e9b9-4a67-9627-aec23ae60ad7" TYPE="ext4" PARTLABEL="nfs" PARTUUID="505d8706-4cd5-4570-ba9f-7b72d71e41f8"
sudo nano /etc/fstab
# auto-mount the partition at boot
UUID=efabbd25-e9b9-4a67-9627-aec23ae60ad7 /media/dylan/nfs	auto defaults 0 0
# create a bind mount to our NFS export folder
/media/dylan/nfs /export/nfs auto bind,rw 0 0
```
| Sources: https://help.ubuntu.com/community/NFSv4Howto
http://www.citi.umich.edu/projects/nfsv4/linux/using-nfsv4.html
https://rancher.com/docs/rancher/v2.x/en/cluster-admin/volumes-and-storage/examples/nfs/

## Install the NFS share provisioner to the cluster
https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.86.29 \
    --set nfs.path=/export/nfs
    
# to uninstall
helm uninstall nfs-subdir-external-provisioner
```