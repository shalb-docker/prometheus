#!/bin/bash

mounts=$(cat /proc/mounts  | grep rw | grep "ext\|xfs" | awk '{print $2}')

rm -f {{ monit_includes_dir }}mounts.conf
for disk in $mounts; do
    disk_name=$(echo $disk | sed s@^/@disk_/@)
    echo \
"# description: check if mount flags changed
CHECK FILESYSTEM ${disk_name}-P3-team_noalert WITH PATH $disk
  IF CHANGED FSFLAGS THEN alert

# description: check if mount writable
CHECK PROGRAM ${disk_name}_writable-P3-team_noalert PATH \"/usr/local/scripts/monit/file_system_writable.sh ${disk}\" EVERY 6 CYCLES
  IF STATUS != 0 THEN alert
" >> {{ monit_includes_dir }}mounts.conf
done

mounts=$(cat /proc/mounts  | grep rw | grep "nfs" | awk '{print $2}')

for disk in $mounts; do
    disk_name=$(echo $disk | sed s@^/@disk_nfs_/@)
    echo \
"# description: check if mount flags changed
CHECK FILESYSTEM ${disk_name}-P3-team_noalert WITH PATH $disk
  IF CHANGED FSFLAGS THEN alert
" >> {{ monit_includes_dir }}mounts.conf
done

