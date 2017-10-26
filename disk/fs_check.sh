#!/bin/bash

function get_devices() {
  lsblk -d -lo NAME -p | grep -v NAME | grep -v "/dev/sr"
}

function list_failures_disk() {
  smartctl -l selftest $1 | grep "#" | tr -s " " | grep failure | awk 'NF{ print $NF }' 
}
function get_partitions_disk() {
  fdisk -l "$1" -o Device,Start,End | grep "$1" | grep -v Disk | tr -s " "
}
function search_partition() {
  disk=$1
  lba=$2
  partition_list=( $( get_partitions_disk "$disk" ) )
  length=${#partition_list[@]}
  for ((i=0;i<$length;i+=3))
  do
    partition=${partition_list[$i]}
    start_lba=${partition_list[($i+1)]}
    end_lba=${partition_list[($i+2)]}
    if [ $lba -ge $start_lba ] && [ $lba -le $end_lba ] 
    then
      echo "$partition"
      break
    fi
  done
}

function check_disk_ok() {
  echo "Checking smart values"
  failure_lba=( $(list_failures_disk $1) )
  if [ ! -z "$failure_lba" ]
  then
    echo "Disk($1) contains block failures at LBA $failure_lba"
    broken_partition=( $( search_partition $1 $failure_lba ) )
    echo "Failed partition is $broken_partition"
  fi  

}



disks=( $( get_devices  ) )
echo "All disks detected ${disks[@]}"
for disk_name in ${disks[@]}
do
  echo "Testing disk $disk_name"
  check_disk_ok $disk_name
  search_partition $disk_name 184131582
done
