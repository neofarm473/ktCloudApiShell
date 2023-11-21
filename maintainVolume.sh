#! /bin/bash

echo "targetVM=$HOSTNAME"

fdisk /dev/vdb <<EOF
n
p
1


t
8e
w
EOF

pvcreate /dev/vdb1
vgcreate vgdata /dev/vdb1
lvcreate --extent +100%FREE -n lvdata vgdata
mkfs -t xfs /dev/vgdata/lvdata

blkidResponse=$(blkid /dev/vgdata/lvdata)
#echo "blkidResponse: $blkidResponse"
uuid=$(echo $blkidResponse | grep -oP '(?<= UUID=\")[\w-]+')
if [ -z "$uuid" ]; then
    echo "cannot get uuid"
    exit 1
fi
blkid_tmp="UUID=$uuid /data                    xfs    defaults        1 2"
echo $blkid_tmp | sudo tee -a /etc/fstab
