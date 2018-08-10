#!/bin/bash -e
test -d /home/mah/client/mabs/mediawiki || git clone /home/mah/work/code/mediawiki/core /home/mah/client/mabs/mediawiki
cd /home/mah/client/mabs/mediawiki
git remote set-url origin https://gerrit.wikimedia.org/r/mediawiki/core.git
git fetch
branch=`git branch -q | awk '/^\*/ {print $2}'`
test "$branch" = "REL1_31" || git checkout REL1_31
git submodule update --init
echo on REL1_31
cd /home/mah/client/mabs

grep -q "/home/mah/client/mabs" /etc/exports || echo "/home/mah/client/mabs *(rw,root_squash,subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
