#!/bin/bash -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. $DIR/.envrc

echo 'show databases;' | sudo mysql | grep -q ${DBNAME} ||
	sudo mysqladmin drop -f ${DBNAME}
