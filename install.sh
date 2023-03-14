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

echo -n "Select Number Corrisponding to the Desired Path: "
read diskPathAnswer
diskPath=${fdiskSearchArray[diskPathAnswer-1]}

requestUserPassword() {
	read -sp "Enter Encryption Password: " encryptionPassword
	printf "\n"
	read -sp "Retype Password: " encryptionPasswordConfirm
	if [[ -z $encryptionPassword ]] || [[ $encryptionPassword != $encryptionPasswordConfirm ]]; then
		return 1
	fi
	return 0
}

requestUserPassword
while [ $? -ne 0 ]; do
	echo "Sorry the passwords you entered does not match"
	requestUserPassword
done

sed -sr 's|''\$DISK_PATH''|'"$diskPath|g" ./templates/create-partition.exp.template > create-partition.exp
chmod +x create-partition.exp
./create-partition.exp

# Format Partitions
listAllDisksTemplate="fdisk -l DISK_PATH | grep -E -o 'DISK_PATH[0-9]'"
listAllDisksCMD=$(echo "$listAllDisksTemplate" | sed "s|DISK_PATH|$diskPath|g")
readarray -t listAllDisksArray <<< $(eval "$listAllDisksCMD")
echo "These partitions were created: ${listAllDisksArray[@]}"

encryptionPartition=${listAllDisksArray[-1]}

# Encrypt Data Partition
sed -sr -e 's|''\$DISK_PATH''|'"${encryptionPartition}|g" -e 's|''\$PASSWORD''|'"${encryptionPassword}|g" ./templates/encrypt-partition.exp.template > encrypt-partition.exp
chmod +x encrypt-partition.exp
./encrypt-partition.exp

# Open Encrypted Partition
sed -sr -e 's|''\$DISK_PATH''|'"${encryptionPartition}|g" -e 's|''\$PASSWORD''|'"${encryptionPassword}|g" ./templates/decrypt-partition.exp.template > decrypt-partition.exp
chmod +x decrypt-partition.exp
./decrypt-partition.exp

# Clean up
rm create-partition.exp
