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

function get_block_size() {
  tune2fs -l $1 | grep "Block size" | awk 'NF{ print $NF }'
}

function is_block_in_use() {
  partition=$1
  test_byte=$2
  debugfs "$partition" -R "testb $test_byte" | grep "marked in use" 
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
      echo "$partition $start_lba"
      break
    fi
  done
}

function get_file() {
  partition=$1
  test_byte=$2
  inode=$( debugfs "$partition" -R "icheck $test_byte" | grep "$test_byte" | awk 'NF{ print $NF }' ) 
  file_name=$( debugfs "$partition" -R "ncheck $inode" | grep "$inode" | awk 'NF{ print $NF }' )
  echo "$file_name"
}

function check_disk_ok() {
  echo "Checking smart values"
  failure_lba=( $(list_failures_disk $1) )
  if [ ! -z "$failure_lba" ]
  then
    echo "Disk($1) contains block failures at LBA $failure_lba"
    echo "Failure:disk:$1"
    broken_partition=( $( search_partition $1 $failure_lba ) )
    partition_name=${broken_partition[0]}
    partition_start=${broken_partition[1]}
    block_size=( $( get_block_size $broken_partition ))
    echo "Failed partition is $broken_partition, $partition_start, $block_size"
    broken_block=$(((( $failure_lba-$partition_start )*512 )/$block_size ))
    echo "Broken block $broken_block"
    if [ ! -z "$(is_block_in_use $partition_name $broken_block)" ]
    then
      echo "Block is in use"
      broken_file=$(get_file $partition_name $broken_block)
      echo "Failure:file:$partition_name:$failure_lba:$broken_block:$broken_file"
    else
      echo "Block not in use"
    fi
  fi  
}



disks=( $( get_devices  ) )
echo "All disks detected ${disks[@]}"
for disk_name in ${disks[@]}
do
  echo "Testing disk $disk_name"
  check_disk_ok $disk_name
done
