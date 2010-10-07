#!/usr/bin/env bash
# create_exclusions.sh
# version 4

# This script will ask about each file and directory
# in a chosen directory and make a list of items for 
# rsync to ignore.  It will also allow you to add items
# to the list of rsync exclusions.

# Examples of excluding subdirectories by entering relative paths:
# To exclude your .mozilla browser cache without
# excluding the rest of .mozilla, enter:
# */Cache/*
# To exclude letters that you have
# stored under /home/$USER/Documents, enter:
# Documents/letters

# See comments for possible modifications to this script.

clear; date
echo

#################
echo -n "
    Give the full path of the top-level
    directory you want to back up.
    (e.g. /home/<username>) : "
read BU_DIR

echo -n "
    Give the full path (with filename)
    to the rsync exclusions file: "
read EXCLUSIONS
################

# Uncomment these two lines, and comment out the above
# section to use your own pre-defined variables.
#BU_DIR="/home phred"
#EXCLUSIONS="/root/scripts/rsync_test_create_exclusions"


function check_root {
if [[ $(id -u) -ne 0 ]]
then
    echo "
    rerun as root"
    echo 
    exit 0
fi
}


function ask_exclusions {
        for e in * ; do
        echo -n "
        Exclude $e? (y/N/all/none): "
        read answer
        case "${answer:0:1}" in 
            [Yy]) echo $e >> "$EXCLUSIONS" ; echo "$e will be skipped" ;;
           [all]) ls -1 >> "$EXCLUSIONS" ; echo "All non-hidden items in this directory will be excluded." ; break ;;
          [none]) echo "All non-hidden items in this directory will be backed up." ; touch "$EXCLUSIONS" ; break ;;
               *) echo "$e will be backed up" ;;
        esac 
    cd -
done
}


function exclude_hidden {
    cd "$BU_DIR"
    for e in $(ls -Ad .*) ; do
    if ! [[ $e = "." || $e = ".."  ]] 
    then
        echo -n "
        Exclude $e? (y/N/all/none): "
        read answer
        case "${answer:0:1}" in 
            [Yy]) echo $e >> "$EXCLUSIONS" ; echo "$e will be skipped" ;;
           [all]) echo ".[a-z,A-Z,0-9]*" >> "$EXCLUSIONS" ; echo "All hidden items in this directory will be excluded." ; break ;;
          [none]) echo "All hidden items in this directory will be backed up." ; touch "$EXCLUSIONS" ; break ;;
               *) echo "$e will be backed up" ;;
        esac 
    fi
    cd -
done
}

 
function more_exclusions {
	while true; do
	echo -n "
	Anything else to exclude? 
	Enter a relative path here
	or n for no.
          "
	read answer 
        case "$answer" in
        [Nn]*) echo "Done listing exclusions." ;  break ;;
            *) echo "$answer" >> "$EXCLUSIONS" ; echo "$answer will be excluded" ;;
    esac
done 
}


# Comment out this line if you want
# to run as a normal user.
check_root

# Warn the user if there are too many items (default 16)
cd "$BU_DIR"
if [[ $(ls | wc -l) > 16 ]]
then
    echo "
    You have $(ls | wc -l) items in this directory, 
    and each one requires an answer. 
    This could take awhile.
    "
fi


# Check to see if the exclusions file exits,
# and give the user the option to abort.

if [[ -e "$EXCLUSIONS" ]]
then
    echo "
    An exclusions file already exists. 
    If you continue, it will be deleted,
    and a new one generated. Else you can 
    exit, in case you want to move the file.
        
    Continue? (y/N) 
        "
    read answer
    case "$answer" in
        [Yy]*) echo "Removing $EXCLUSIONS
                      " ; rm "$EXCLUSIONS" ;;
            *) echo "Aborting...
            " ; exit 0 ;;
    esac
else
    echo "
    This script will help you create a file
    containing a list of files/directories to
    be excluded from your rsync backup. Read the
    comments inside the script for more information.
       
    Continue? (y/N)
       "
    read answer
    case "$answer" in
        [Yy]*) echo "OK
                     " ;;
            *) echo "Aborting...
            " ; exit 0 ;;
    esac
fi


# To exclude all hidden items automatically, uncomment the next line, 
# and comment out "exclude_hidden" below. To automatically include all
# hidden items, just commant out "exclude_hidden" below.

#echo ".[a-z,A-Z,0-9]*" >> "$EXCLUSIONS"

ask_exclusions
exclude_hidden
more_exclusions


# Show the exclusions file, and exit
echo "
     Here's the exclusions file.
     If you typed something wrong,
     you can edit the file manually.
     "
sleep 3
echo
cat "$EXCLUSIONS"
echo

exit 0

