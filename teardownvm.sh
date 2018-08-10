#!/bin/bash -e
up=`sudo virsh list --all | grep mabs || true`
if [ -n "$up" ]; then
	sudo virsh destroy mabs
	sudo virsh undefine mabs
	sudo rm /home/mah/MachineImages/mabs.img
else
	echo Nothing to do
fi
