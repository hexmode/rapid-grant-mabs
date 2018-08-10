#!/bin/bash -e
connect() {
	name=$1
	total=$2

	echo Attempting to connect to $name
	set +e
	count=1
	false
	until [ $? -eq 0 -o $count -eq $total ]; do
		if [ $count -ne 1 ]; then
			sleep 1
			echo "Attempting to connect ( $count / $total )"
		fi
		count=$(($count + 1))
		ssh -o UserKnownHostsFile=hostpubkey $name -o ConnectTimeout=1 echo $name is up 2> /dev/null
	done
	set -e
}

if [ ! -f "/home/mah/MachineImages/mabs.img" ]; then
	sudo virt-clone --original mediawiki-debian --name "mabs" --file "/home/mah/MachineImages/mabs.img"
fi

sudo virsh list --all | grep -q mabs.*run || sudo virsh start mabs

connect debian.default 10

if [ $count -ge $total ]; then
	echo "Couldn't start mabs"
	exit 1
fi

eval "ssh -o UserKnownHostsFile=hostpubkey debian.default sudo sed -i s,debian,mabs,g /etc/hostname"
eval "ssh -o UserKnownHostsFile=hostpubkey debian.default sudo sed -i s,debian,mabs,g /etc/hosts"
eval "ssh -o UserKnownHostsFile=hostpubkey debian.default sudo reboot"

connect mabs.default 10
