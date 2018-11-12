#!/bin/bash -e
sed -i s,debian.default,${HOST}, hostpubkey
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo apt update"
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo apt upgrade -y"
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo apt install -y php-zip memcached imagemagick clamav php-cli php-intl php-curl php-wikidiff2 python apache2 php php-mysqlnd php-mbstring php-xml mime-support libapache2-mod-fcgid php-fpm"

eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo apt install -y nfs-common"
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} mkdir -p ${DIR}"
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} cat /etc/fstab" | grep -q "${DIR}" || echo "${HOSTSERVER}:${DIR} ${DIR} nfs rw,soft,user 0 0" | eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo tee -a /etc/fstab"
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} mount ${DIR}"

sudo apt install moreutils # for sponge
echo '{}' > composer.local.json
jq '.["require"]["mediawiki/semantic-media-wiki"] = "^2.5"' composer.local.json | sponge composer.local.json
jq '.["require"]["mediawiki/mabs"] = "dev-master"' composer.local.json | sponge composer.local.json

rm -f ${MW_INSTALL_Path}/composer.local.json && ln -s ${DIR}/composer.local.json ${MW_INSTALL_Path}/composer.local.json

if [ ! -f composer ];then
	./getcomposer.sh
fi
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sh -c \"'cd ${MW_INSTALL_Path} ; php ${DIR}/composer -v update 2>&1'\""

rm -f LocalSettings.php
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} php ${MW_INSTALL_Path}/maintenance/install.php --dbserver=${DBSERVER} --dbname=${DBNAME} --confpath=${DIR} --scriptpath=${WIKIPATH} --installdbpass=${WIKIDBPASS} --installdbuser=${WIKIDBUSER} --server=${WIKISERVER} --pass=${WIKIPASS} ${WIKI} ${WIKIUSER} 2>&1"

sed -i "s,^.wgSitename =.*,\$wgSitename = getenv('WIKI');," LocalSettings.php
sed -i "s,^.wgMetaNamespace =.*,\$wgMetaNamespace = ucfirst( getenv('WIKI') );," LocalSettings.php
sed -i "s,^.wgScriptPath =.*,\$wgScriptPath = getenv('WIKIPATH');," LocalSettings.php
sed -i "s,^.wgServer =.*,\$wgServer = getenv('WIKISERVER');," LocalSettings.php
sed -i "s,^.wgDBserver =.*,\$wgDBserver = getenv('DBSERVER');," LocalSettings.php
sed -i "s,^.wgDBname =.*,\$wgDBname = getenv('DBNAME');," LocalSettings.php
sed -i "s,^.wgDBuser =.*,\$wgDBuser = getenv('WIKIDBUSER');," LocalSettings.php
sed -i "s,^.wgDBpassword =.*,\$wgDBpassword = getenv('WIKIDBPASS');," LocalSettings.php
rm -f ${MW_INSTALL_Path}/LocalSettings.php && ln -s ${DIR}/LocalSettings.php ${MW_INSTALL_Path}
rm -f ${MW_INSTALL_Path}/.htaccess && ln -s ${DIR}/.htaccess ${MW_INSTALL_Path}

if [ "${DEBUG}" = "y" ]; then
	grep -q __DIR__..../Debug.php LocalSettings.php || echo 'require __DIR__ . "/Debug.php";' | tee -a LocalSettings.php
fi

grep -q ParserFunctions LocalSettings.php || echo "wfLoadExtension( 'ParserFunctions' );" | tee -a LocalSettings.php
grep -q MABS LocalSettings.php || echo "wfLoadExtension( 'MABS' );" | tee -a LocalSettings.php

eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sh -c \"'. ${DIR}/.envrc; php ${MW_INSTALL_Path}/maintenance/update.php --quick'\""

eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo cp ${DIR}/wiki.conf /etc/apache2/conf-available"
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo a2enconf wiki"
eval "ssh -o UserKnownHostsFile=hostpubkey ${HOST} sudo service apache2 reload"

rm -f ${MW_INSTALL_Path}/.htaccess
ln -s ${DIR}/.htaccess ${MW_INSTALL_Path}/.htaccess
