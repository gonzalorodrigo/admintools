#!/bin/bash

function get_devices() {
  lsblk -d -lo NAME -p | grep -v NAME | grep -v "/dev/sr"
}
disks=( $( get_devices  ) )
echo "${disks[@]}"
for disk_name in ${disks[@]}
do
  echo "Testing disk $disk_name"

done
