#!/bin/bash

clear; date
echo 

# Variables
PATH_BU="/root/backup"
TARGET_PATH="/home/$1"
TARGET_NAME="$1_configs"
GPG_FILE="$PATH_BU/backup_$TARGET_NAME.tar.gz.gpg"
TAR_FILE="$PATH_BU/backup_$TARGET_NAME.tar.gz"
EXCLUDE_FILE="/root/Configs/fsmithsred_backup_scripts/rsync_userconfig_excludes"



# Functions: check_root; ask_for; clean_up;check_exit
function check_root {
if [[ $(id -u) -ne 0 ]]
then
    echo "
    rerun as root"
    echo 
    exit 0
fi
}


function ask_for {
echo -n "
    You want to go on? (answer yes or no): "
read answer
if [[ $answer = yes ]] || [[ $answer = y ]]  || [[ $answer = Yes ]] || [[ $answer = Y ]] 
then
    echo "
    Ok, we will move on."
    echo
else
    echo "
    Your answer has not been yes.
    Script will die now."
    echo 
    clean_up
    exit 1
fi
}


function clean_up {
echo -n "
    Cleaning up...
    "
    rm -r "$PATH_BU"/"$TARGET_NAME"
    rm "$TAR_FILE"
}


function check_exit {
if  [[ $? -ne 0 ]]
then
    echo "
    An error occured"
    echo
    clean_up
    exit 0
fi 
}  

# the help text will be shown in case the user uses the -h option
help_text="
Usage is a simple:
$0  <username>

This script will backup the hidden directories in your home.
The result will be tarred, gzipped and encrypted with gpg.
It will be stored as:
$PATH_BU/backup_$TARGET_NAME.tar.gz.gpg

See rsync_userconfig_excludes for the list of exclusions.
Make sure the correct path is set in the variable EXCLUDE_FILE
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

# check for the first argument, the users name
if [[ "$#" -ne 1 ]]
then
    echo "$help_text"
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
    rsync -auvx --delete-after --exclude-from="$EXCLUDE_FILE" $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME
    "
    ask_for
    rsync -auvx --delete-after --exclude-from="$EXCLUDE_FILE"  $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME
    check_exit 
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

# remove this once the first troubleshooting is done
#exit 0



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
    rsync -auvx --delete-after --exclude-from="$EXCLUDE_FILE" $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME
    "
    ask_for
    rsync -auvx --delete-after --exclude-from="$EXCLUDE_FILE" $TARGET_PATH/.[a-z,A-Z,0-9]* $PATH_BU/$TARGET_NAME
    check_exit

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
