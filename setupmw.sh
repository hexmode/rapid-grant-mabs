#!/bin/bash -e
sed -i s,debian.default,mabs.default, hostpubkey
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo apt update"
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo apt upgrade -y"
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo apt install -y php-zip memcached imagemagick clamav php-cli php-intl php-curl php-wikidiff2 python apache2 php php-mysqlnd php-mbstring php-xml mime-support libapache2-mod-fcgid php-fpm"

eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo apt install -y nfs-common"
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default mkdir -p /home/mah/client/mabs"
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default cat /etc/fstab" | grep -q "/home/mah/client/mabs" || echo "10.5.5.1:/home/mah/client/mabs /home/mah/client/mabs nfs rw,soft,user 0 0" | eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo tee -a /etc/fstab"
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default mount /home/mah/client/mabs"

sudo apt install moreutils # for sponge
echo '{}' > composer.local.json
jq '.["require"]["mediawiki/semantic-media-wiki"] = "^2.5"' composer.local.json | sponge composer.local.json
jq '.["require"]["mediawiki/mabs"] = "dev-master"' composer.local.json | sponge composer.local.json

rm -f /home/mah/client/mabs/mediawiki/composer.local.json && ln -s /home/mah/client/mabs/composer.local.json /home/mah/client/mabs/mediawiki/composer.local.json

if [ ! -f composer ];then
	./getcomposer.sh
fi
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sh -c \"'cd /home/mah/client/mabs/mediawiki ; php /home/mah/client/mabs/composer -v update 2>&1'\""

rm -f LocalSettings.php
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default php /home/mah/client/mabs/mediawiki/maintenance/install.php --dbserver=10.5.5.1 --dbname=mabs --confpath=/home/mah/client/mabs --scriptpath=/wiki --installdbpass=wikipass --installdbuser=wikiuser --server=http://mabs.default --pass=none1234 mabs MarkAHershberger 2>&1"

sed -i "s,^.wgSitename =.*,\$wgSitename = getenv('WIKI');," LocalSettings.php
sed -i "s,^.wgMetaNamespace =.*,\$wgMetaNamespace = ucfirst( getenv('WIKI') );," LocalSettings.php
sed -i "s,^.wgScriptPath =.*,\$wgScriptPath = getenv('WIKIPATH');," LocalSettings.php
sed -i "s,^.wgServer =.*,\$wgServer = getenv('WIKISERVER');," LocalSettings.php
sed -i "s,^.wgDBserver =.*,\$wgDBserver = getenv('DBSERVER');," LocalSettings.php
sed -i "s,^.wgDBname =.*,\$wgDBname = getenv('DBNAME');," LocalSettings.php
sed -i "s,^.wgDBuser =.*,\$wgDBuser = getenv('WIKIDBUSER');," LocalSettings.php
sed -i "s,^.wgDBpassword =.*,\$wgDBpassword = getenv('WIKIDBPASS');," LocalSettings.php
rm -f /home/mah/client/mabs/mediawiki/LocalSettings.php && ln -s /home/mah/client/mabs/LocalSettings.php /home/mah/client/mabs/mediawiki
rm -f /home/mah/client/mabs/mediawiki/.htaccess && ln -s /home/mah/client/mabs/.htaccess /home/mah/client/mabs/mediawiki

if [ "y" = "y" ]; then
	grep -q __DIR__..../Debug.php LocalSettings.php || echo 'require __DIR__ . "/Debug.php";' | tee -a LocalSettings.php
fi

grep -q ParserFunctions LocalSettings.php || echo "wfLoadExtension( 'ParserFunctions' );" | tee -a LocalSettings.php
grep -q MABS LocalSettings.php || echo "wfLoadExtension( 'MABS' );" | tee -a LocalSettings.php

eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sh -c \"'. /home/mah/client/mabs/.envrc; php /home/mah/client/mabs/mediawiki/maintenance/update.php --quick'\""

eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo cp /home/mah/client/mabs/wiki.conf /etc/apache2/conf-available"
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo a2enconf wiki"
eval "ssh -o UserKnownHostsFile=hostpubkey mabs.default sudo service apache2 reload"

rm -f /home/mah/client/mabs/mediawiki/.htaccess
ln -s /home/mah/client/mabs/.htaccess /home/mah/client/mabs/mediawiki/.htaccess
