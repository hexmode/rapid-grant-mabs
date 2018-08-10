#!/bin/bash -e
ssh -o UserKnownHostsFile=hostpubkey mabs.default 'mkdir -p /home/mah/repo; chmod 1777 /home/mah/repo'
grep -q MABSrepo.*= LocalSettings.php || echo '$MABSrepo = "/home/mah/repo";' | tee -a LocalSettings.php
