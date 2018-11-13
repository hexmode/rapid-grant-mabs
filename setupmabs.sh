#!/bin/bash -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. $DIR/.envrc

ssh -o UserKnownHostsFile=hostpubkey ${HOST} "mkdir -p ${REPO_DIR}; chmod 1777 ${REPO_DIR}"
grep -q MABSRepo.*= LocalSettings.php ||
	 echo "\$MABSRepo = '${REPO_DIR}';" | tee -a LocalSettings.php
