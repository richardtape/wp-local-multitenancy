#!/bin/bash

# Downloads the specified version of WordPress into a directory called the same as the version number
# i.e. ./newwp.sh -v 4.7.2
# will download WordPress 4.7.2 into a directory ./wordpress/4.7.2
# uses wp-cli and will overwrite any existing directory with the same name

version=''
checkmark='✓'

# get the flags from the command line
while getopts 'v:' flag; do

    case "${flag}" in
        v) version="${OPTARG}" ;;
        *) echo "Unexpected option ${flag}" ;;
    esac

done

# Use wp-cli to download this version into the specified directory
echo -ne "[ ] Downloading WordPress ${version}\r"
wp core download --version=${version} --path=wordpress/${version} --force --quiet
echo -ne "[${checkmark}] Downloading WordPress ${version}\r"
