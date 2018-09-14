#!/bin/bash -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. .envrc

test -d ${MW_INSTALL_DIR} || git clone ${LOCAL_GIT} ${MW_INSTALL_DIR}
cd ${MW_INSTALL_DIR}
git remote set-url origin ${UPSTREAM_GIT}
git fetch
branch=`git branch -q | awk '/^\*/ {print $2}'`
test "$branch" = "${RELBRANCH}" || git checkout ${RELBRANCH}
git submodule update --init
echo on ${RELBRANCH}
cd $DIR

grep -q "${DIR}" /etc/exports || echo "${DIR} *(rw,root_squash,subtree_check)" | sudo tee -a /etc/exports
sudo exportfs -ra
