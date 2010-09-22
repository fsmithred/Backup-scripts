#!/bin/bash

# Later version(s) of this exit at http://github.com/tornow/backup_scripts
# filename FSR-blah (not sure at this point.)

# This one is live (no -n in the rsync)
# but it's definitely not ready for use. 
#
# 4.04 - Might be ready.
# 4.04 - added a test for argument
# 4.04 - added a test for /home/$1
# 4.03 - Cleaned up and commented. Then dirtied it some more.
# Need to be able to input the user's name.
# Changed it to TARGET_PATH="/home/$1"
# with no sanity checks. 
# Maybe:
#   check if directory exists?
#   check if argument exists?
#   check if username is in /etc/passwd? 


### Next line is not true if /home/$1 works.
# You MUST Edit TARGET_PATH (No trailing slahses) unless your user's name is user.
# and TARGET_NAME (No slashes) to your liking.
# Edit the rsync_userconfig_excludes file to add or remove items to be excluded.
# If you want a date-stamped duplicate file for permanent archive, then
# uncomment the two lines that look like this (but not this one!):
#  #    cp "$GPG_FILE" backup_"$TARGET_NAME"_$(date +%Y%m%d).tar.gz.gpg   

PATH_BU="/root/backup"
TARGET_PATH="/home/$1"
TARGET_NAME="$1_configs"
GPG_FILE="$PATH_BU/backup_$TARGET_NAME.tar.gz.gpg"
TAR_FILE="$PATH_BU/backup_$TARGET_NAME.tar.gz"


source backup_functions
clear; date
echo 

# the help text will be shown in case the user uses the -h option
help_text="
Usage is a simple:
$0  <username>

This script will backup the hidden directories in your home.
The result will be tarred, gzipped and encrypted with gpg.
It will be stored as:
$PATH_BU/backup_$TARGET_NAME.tar.gz.gpg

See rsync_userconfig_excludes for the list of exclusions.
" 

while getopts h option
do
case $option in
                h) echo "$help_text" ;
                   exit 0
        esac
done


# Comment out check_root if you want to run the script as an unprivileged user.
check_root


########  Begin new part ###########

# check for argument
if [[ $# -ne 1 ]]
then
    echo "
    Usage:
    $0  <username>
    "
    exit 0
fi


# check for source directory
if ! [[ -d $TARGET_PATH ]]
then
    echo "
        $TARGET_PATH does not exist.
        Use a valid user name.
        "
    exit 0
else
    echo "
        Getting ready to back up hidden directories 
        and files in $TARGET_PATH. 
        "
fi

#######  End new part  ############


# create PATH_BU if necessary
if ! [[ -d $PATH_BU ]] 
then
    mkdir "$PATH_BU" 
fi 
cd "$PATH_BU"


# Test for first run

if ! [[ -f $GPG_FILE ]]
then
    echo "
    About to run:
    rsync -auvx --delete-after --exclude-from=/root/rsync_userconfig_excludes $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME
    "
    ask_for
    rsync -auvx --delete-after --exclude-from=/root/rsync_userconfig_excludes $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME
    tar -czf "$TAR_FILE" "$TARGET_NAME"
    gpg -c "$TAR_FILE"
    clean_up
# Uncomment this next line if you want a date-stamped 
# duplicate file for permanent archive on the first run.
#    cp "$GPG_FILE" backup_"$TARGET_NAME"_$(date +%Y%m%d).tar.gz.gpg
    echo "
    This was the first run of your backup.
    We created a backup_file called
    $GPG_FILE
    "
    echo
    exit 0
fi


# Repeat runs

# Decrypt and untar the backup file.

gpg --output "$TAR_FILE" --decrypt "$GPG_FILE"

echo "
    The backup file was decrypted.
    Please wait for it to be untarred.
    "
sleep 2

tar -xzf "$TAR_FILE"


# RSYNC
echo "
    About to run:
    rsync -auvx --delete-after --exclude-from=/root/rsync_userconfig_excludes $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME
    "
    ask_for
    rsync -auvx --delete-after --exclude-from=/root/rsync_userconfig_excludes $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME


# Archive and encrypt the new backup, clean up.
echo "
    The new backup will be archived and encrypted.
    Give it a passphrase.
    "

rm "$TAR_FILE"
rm "$GPG_FILE"

tar -czf "$TAR_FILE" "$TARGET_NAME"
gpg -c "$TAR_FILE"
clean_up


# Uncomment this next line if you want a date-stamped 
# duplicate file for permanent archive on repeat runs.
#    cp "$GPG_FILE" backup_"$TARGET_NAME"_$(date +%Y%m%d).tar.gz.gpg


echo "Done!"

exit 0
