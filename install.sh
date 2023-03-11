#!/usr/bin/bash

# Install pre-requirements
pacman -S --noconfirm expect


fdiskSearch=$(fdisk -l | grep -E --color=never -oi '/dev/(mapper/[a-z0-9\-]+|[a-z0-9]+)')
readarray -t fdiskSearchArray <<<"$fdiskSearch"

index=1

for disk in "${fdiskSearchArray[@]}"
do
	echo "$index $disk"
	let "index+=1"
done

echo -n "Enter Something: "
read answer
diskPath=${fdiskSearchArray[answer-1]}

sed -r "s|DISK_PATH|${diskPath}|" create-partition.exp.template > create-partition.exp
chmod +x create-partition.exp
./create-partition.exp

# Format Partitions
listAllDisksTemplate="fdisk -l DISK_PATH | grep -E -o 'DISK_PATH[0-9]'"
listAllDisksCMD=$(echo "$listAllDisksTemplate" | sed "s|DISK_PATH|$diskPath|g")
readarray -t listAllDisksArray <<< $(eval "$listAllDisksCMD")
echo "These partitions were created: ${listAllDisksArray[@]}"

rm create-partition.exp
