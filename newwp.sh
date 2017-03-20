#!/bin/bash

# Downloads the specified version of WordPress into a directory called the same as the version number
# i.e. ./newwp.sh
# will download WordPress into a directory ./wordpress/<ver_num>
# uses wp-cli and will overwrite any existing directory with the same name

checkmark='✓'

# get the flags from the command line
while getopts 'v:' flag; do

    case "${flag}" in
        *) echo "Unexpected option ${flag}" ;;
    esac

done

echo ''

echo "Which version of WordPress would you like to download? i.e. 4.7.3: "
read version

echo "Would you like to make this newly downloaded version of WordPress the current live version across all sites? Type 'yes' or 'no' [default no]"
read makelive

# Use wp-cli to download this version into the specified directory
echo -ne "[ ] Downloading WordPress ${version}\r"
wp core download --version=${version} --path=wordpress/${version} --force --quiet
echo -ne "[${checkmark}] Downloading WordPress ${version}\r"

# If makelive === 'yes' then we adjust the ./wordpress/stable symlink
if [ 'yes' = $makelive ]; then

    echo -ne "[ ] Putting WordPress ${version} live\r"
    cd wordpress && ln -sfn ${version} stable
    echo -ne "[${checkmark}] Putting WordPress ${version} live\r"

fi
