#!/bin/bash

# Create a new site local to where this script is located.
# Usage: ./newsite.sh [-n /path/to/nginx/config]
# based on answer to questions it asks you;
# Creates a new directory 'domain.com' and
# domain.com/content
# domain.com/index.php
# domain.com/wp-config.php
# domain.com/wp (symlink to ./wordpress/stable)

checkmark='✓'

# nginx location to allow someone to override
nginxlocation='/usr/local/etc/nginx/sites-enabled'

# get the flags from the command line
while getopts 'n:' flag; do

    case "${flag}" in
        n) nginxlocation="${OPTARG}" ;;
        *) echo "Unexpected option ${flag}" ;;
    esac

done

# This is where we start
pwd=$(pwd)

echo ''
echo "We are going to need a few things from you to help set this site up. You'll be prompted to enter some connection details."

echo "Enter the live domain for this site i.e. mysite.com: "
read domain

echo "Enter the development/local domain for this site i.e. mysite.dev: "
read localdomain

echo "Enter the local database username: "
read dbusername

echo "Enter the local database password (will be hidden): "
read -s dbpassword


# Check if the dirctor exists for this domain, if so, bail
if [ -d "$domain" ]; then

    printf "\nError: The directory ${domain} already exists. Exiting.\n"
    exit 1

fi

# OK, the dir doesn't exist, so let's create the file/folder structure
echo ''
echo "-- Creating file and folder structure for {$domain} --"

echo -ne "[ ] Content directory\r"
mkdir ${domain} ${domain}/content/ ${domain}/content/plugins ${domain}/content/themes ${domain}/content/uploads ${domain}/ssl
ln -s ../shared/mu-plugins ${domain}/content/mu-plugins
echo -ne "[${checkmark}] Content directory\r"

echo ''

echo -ne "[ ] Symlink for WordPress\r"
ln -s ../wordpress/stable ${domain}/wp
echo -ne "[${checkmark}] Symlink for WordPress\r"

echo ''

echo -ne "[ ] Adding index.php\r"
cp shared/index.php ${domain}/index.php
echo -ne "[${checkmark}] Adding index.php\r"

echo ''

echo -ne "[ ] Generate a wp-config.php file\r"
cp -LR wordpress/stable wordpress/workingdir
wp core config --dbname=${domain} --dbuser=${dbusername} --dbpass=${dbpassword} --path=wordpress/workingdir/stable --skip-check --quiet --extra-php <<PHP
define( 'WP_CONTENT_DIR', dirname( __FILE__ ) . '/content' );
PHP
cp wordpress/workingdir/stable/wp-config.php ${domain}
rm -rf wordpress/workingdir/stable
echo -ne "[${checkmark}] Generate a wp-config.php file\r"

echo ''

echo -ne "[ ] Adding SSL Certificate\r"

cd ${domain}/ssl && cat > openssl.cnf <<-EOF
  [req]
  distinguished_name = req_distinguished_name
  x509_extensions = v3_req
  prompt = no
  [req_distinguished_name]
  CN = *.${localdomain}
  [v3_req]
  keyUsage = keyEncipherment, dataEncipherment
  extendedKeyUsage = serverAuth
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = *.${localdomain}
  DNS.2 = ${localdomain}
EOF

# Generate new SSL Cert and ensure output isn't shown as it looks ugly
openssl req -new -newkey rsa:2048 -sha1 -days 3650 -nodes -x509 -keyout ssl.key -out ssl.crt -config openssl.cnf &>/dev/null

rm openssl.cnf

open /Applications/Utilities/Keychain\ Access.app ssl.crt

echo -ne "[${checkmark}] Adding SSL Certificate\r"

echo ''

echo -ne "[ ] Adding nginx configuration\r"
cd ${pwd} && cp ./shared/nginx-site-template.conf ${nginxlocation}/
mv ${nginxlocation}/nginx-site-template.conf ${nginxlocation}/${domain}
sed -i .bak "s/{{LOCALDOMAIN}}/${localdomain}/g" ${nginxlocation}/${domain}
sed -i .bak "s/{{DOMAINNAME}}/${domain}/g" ${nginxlocation}/${domain}
rm ${nginxlocation}/${domain}.bak
echo -ne "[${checkmark}] Adding nginx configuration\r"

echo ''

# All done
echo "-- Finished setting up {$domain} --"

echo ''

echo "Note: You will need to manually accept the generated SSL certificate if you wish to use https://${localdomain}"
echo "Note: You will need to restart nginx."

echo ''
