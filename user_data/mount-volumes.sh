#!/usr/bin/env bash
#
# Script to mount volumes

while [ ! -b ${device_name} ] ; do sleep 1 ; echo "waiting for EBS to be attached" ; done

# create the mount point
if [ ! -d ${mount_point} ]; then
    mkdir -p ${mount_point}
fi

# mount the volume
if ! grep ${device_name} /etc/mtab > /dev/null; then
    mount ${device_name} ${mount_point} || (mkfs -t ext4 ${device_name} && mount ${device_name} ${mount_point})
fi

# update fstab
if ! grep ${mount_point} /etc/fstab > /dev/null; then
    echo "${device_name} ${mount_point} ext4 defaults,nofail 0 2" >> /etc/fstab
fi
