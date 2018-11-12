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

if [ ! -f "${VMPATH}/${WIKI}.img" ]; then
	sudo virt-clone --original mediawiki-debian --name "${WIKI}" --file "${VMPATH}/${WIKI}.img"
fi

sudo virsh list --all | grep -q ${WIKI}.*run || sudo virsh start ${WIKI}

connect debian.default 10

if [ $count -ge $total ]; then
	echo "Couldn't start ${WIKI}"
	exit 1
fi

eval "ssh -o UserKnownHostsFile=hostpubkey debian.default sudo sed -i s,debian,${WIKI},g /etc/hostname"
eval "ssh -o UserKnownHostsFile=hostpubkey debian.default sudo sed -i s,debian,${WIKI},g /etc/hosts"
eval "ssh -o UserKnownHostsFile=hostpubkey debian.default sudo reboot"

connect ${HOST} 10
