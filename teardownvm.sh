#!/bin/bash -e
up=`sudo virsh list --all | grep ${WIKI} || true`
if [ -n "$up" ]; then
	sudo virsh destroy ${WIKI}
	sudo virsh undefine ${WIKI}
	sudo rm ${VMPATH}/${WIKI}.img
else
	echo Nothing to do
fi
