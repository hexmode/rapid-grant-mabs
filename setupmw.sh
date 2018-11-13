#!/bin/bash -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
. $DIR/.envrc

sshIt() {
	eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} $*"
}

sudoIt() {
	sshIt sudo $*
}

sed -i s,debian.default,${HOST}, hostpubkey
sudoIt apt update
sudoIt apt upgrade -y
sudoIt apt install -y php-zip memcached imagemagick clamav php-cli php-intl php-curl \
	       php-wikidiff2 python apache2 php php-mysqlnd php-mbstring php-xml mime-support \
	       libapache2-mod-fcgid php-fpm

sudoIt apt install -y nfs-common
sshIt mkdir -p ${DIR}
sshIt cat /etc/fstab | grep -q "${DIR}" ||
	echo "${HOSTSERVER}:${DIR} ${DIR} nfs rw,soft,user 0 0" | sudoIt tee -a /etc/fstab
sshIt mount ${DIR}

sudo apt install moreutils # for sponge
echo '{}' > composer.local.json
jq '.["require"]["mediawiki/semantic-media-wiki"] = "^2.5"' composer.local.json |
	sponge composer.local.json
jq '.["require"]["mediawiki/mabs"] = "dev-master"' composer.local.json |
	sponge composer.local.json

rm -f ${MW_INSTALL_PATH}/composer.local.json &&
	ln -s ${DIR}/composer.local.json ${MW_INSTALL_PATH}/composer.local.json

if [ ! -f composer ];then
	./getcomposer.sh
fi
sshIt sh -c "cd ${MW_INSTALL_PATH} ; php ${DIR}/composer -v update 2>&1"

rm -f LocalSettings.php
sshIt php ${MW_INSTALL_PATH}/maintenance/install.php --dbserver=${DBSERVER} --dbname=${DBNAME} \
	      --confpath=${DIR} --scriptpath=${WIKIPATH} --installdbpass=${WIKIDBPASS} \
	      --installdbuser=${WIKIDBUSER} --server=${WIKISERVER} --pass=${WIKIPASS} \
	      ${WIKI} ${WIKIUSER} 2>&1

sed -i "s,^.wgSitename =.*,\$wgSitename = getenv( 'WIKI' );,
		s,^.wgMetaNamespace =.*,\$wgMetaNamespace = ucfirst( getenv( 'WIKI' ) );,
		s,^.wgScriptPath =.*,\$wgScriptPath = getenv( 'WIKIPATH' );,
		s,^.wgServer =.*,\$wgServer = getenv( 'WIKISERVER' );,
		s,^.wgDBserver =.*,\$wgDBserver = getenv( 'DBSERVER' );,
		s,^.wgDBname =.*,\$wgDBname = getenv( 'DBNAME' );,
		s,^.wgDBuser =.*,\$wgDBuser = getenv( 'WIKIDBUSER' );,
		s,^.wgDBpassword =.*,\$wgDBpassword = getenv( 'WIKIDBPASS' );," LocalSettings.php
rm -f ${MW_INSTALL_PATH}/LocalSettings.php && ln -s ${DIR}/LocalSettings.php ${MW_INSTALL_PATH}
rm -f ${MW_INSTALL_PATH}/.htaccess && ln -s ${DIR}/.htaccess ${MW_INSTALL_PATH}

if [ "${DEBUG}" = "y" ]; then
	grep -q __DIR__..../Debug.php LocalSettings.php ||
		echo 'require __DIR__ . "/Debug.php";' | tee -a LocalSettings.php
fi

grep -q ParserFunctions LocalSettings.php ||
	echo "wfLoadExtension( 'ParserFunctions' );" | tee -a LocalSettings.php
grep -q MABS LocalSettings.php ||
	echo "wfLoadExtension( 'MABS' );" | tee -a LocalSettings.php

sshIt sh -c "'. ${DIR}/.envrc; php ${MW_INSTALL_PATH}/maintenance/update.php --quick'"

sudoIt rm -f /etc/apache2/conf-*/wiki.conf
sudoIt cp ${DIR}/wiki.conf /etc/apache2/conf-available
sudoIt a2enconf wiki
sshIt cat /etc/apache2/envvars | grep -q ${DIR}/.envrc ||
	( echo ". ${DIR}/.envrc" | sudoIt tee -a /etc/apache2/envvars )
sudoIt service apache2 stop
sudoIt service apache2 start    # This instead of reload to make sure envvars is used

rm -f ${MW_INSTALL_PATH}/.htaccess
ln -s ${DIR}/.htaccess ${MW_INSTALL_PATH}/.htaccess
