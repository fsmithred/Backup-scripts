#!/usr/bin/env bash
# create_excludes.sh
# version 4.02

# CHANGES 
# 4.02
# added "- "
# changed to "for e in .*" instead of ls blah.
# changed excludes to excludes
# 4.01
# Added option to keep the old file and add to it.
# Added some instructions for y/N/all/none
# removed "touch $EXCLUSIONS"

# This script will ask about each file and directory
# in a chosen directory and make a list of items for 
# rsync to ignore.  It will also allow you to add items
# to the list of rsync excludes.

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
    to the rsync excludes file: "
read EXCLUDES
################

# Uncomment these two lines, and comment out the above
# section to use your own pre-defined variables.
#BU_DIR="/home phred"
#EXCLUDES="/root/scripts/rsync_test_create_excludes"


function check_root {
if [[ $(id -u) -ne 0 ]]
then
    echo "
    rerun as root"
    echo 
    exit 0
fi
}


function ask_excludes {
        for e in * ; do
        echo -n "
        Exclude $e? (y/N/all/none): "
        read answer
        case "$answer" in 
            [Yy]*) echo "- $e" >> "$EXCLUDES" ; echo "$e will be skipped" ;;
              all) ls -1 "$BU_DIR" >> "$EXCLUDES" ; echo "All non-hidden items in this directory will be excluded." ; break ;;
             none) echo "All non-hidden items in this directory will be backed up." ; break ;;
                *) echo "$e will be backed up" ;;
        esac 
done
}


function exclude_hidden {
    for e in .* ; do
    if ! [[ $e = "." || $e = ".."  ]] 
    then
        echo -n "
        Exclude $e? (y/N/all/none): "
        read answer
        case "$answer" in 
            [Yy]*) echo "- $e" >> "$EXCLUDES" ; echo "$e will be skipped" ;;
              all) echo "- .[a-z,A-Z,0-9]*" >> "$EXCLUDES" ; echo "All hidden items in this directory will be excluded." ; break ;;
             none) echo "All hidden items in this directory will be backed up." ; break ;;
                *) echo "$e will be backed up" ;;
        esac 
    fi
done
}

 
function more_excludes {
	while true; do
	echo -n "
	Anything else to exclude? 
	Enter a relative path here,
        preceded by \"- \" to exclude,
        or \"+ \" to exempt something from
        being excluded (note the space),
	or "n" if you have no other changes. 
          "
	read answer 
        case "$answer" in
        [Nn]*) echo "Done listing excludes." ;  break ;;
            *) echo "$answer" >> "$EXCLUDES" ; echo "$answer will be excluded" ;;
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
sleep 3
fi


# Check to see if the excludes file exits,
# and give the user the option to abort.

if [[ -e "$EXCLUDES" ]]
then
    echo "Contents of $EXCLUDES"
    sleep 1
    cat "$EXCLUDES"
    echo "
    An excludes file already exists. 
    If you continue, it will be deleted,
    and a new one generated. Else you can 
    exit, in case you want to move the file.
        
    Continue and create a new file?    (y or c)
    Keep the old file and add to it?   (k) 
    No, exit the script.               (n)
    
    Answer: "
    read answer
    case "$answer" in
        [Yy]*|[Cc]) echo "Removing $EXCLUDES
                      " ; rm "$EXCLUDES" ;;
         [Kk]) ;;
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

#echo "- .[a-z,A-Z,0-9]*" >> "$EXCLUDES"

# Instructions
echo "
    -------------------------------------------------------------------
    Answer \"y\" to exclude an item from backup.
    Answer \"n\" or Enter to skip an item.
    \"all\" will add all items in a section. (hidden or non-hidden)
    \"none\" will exit a section without adding more files to the list.
    -------------------------------------------------------------------
    "
sleep 1
ask_excludes
exclude_hidden
more_excludes


# Show the excludes file, and exit
echo "
     Here's the excludes file.
     If you typed something wrong,
     you can edit the file manually.
     "
sleep 3
echo
cat "$EXCLUDES"
echo

exit 0

