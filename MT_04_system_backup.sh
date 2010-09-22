#!/bin/bash
# system backup script


clear; date
echo 


# Variables
BU_MP="/media/backup"
BU_DEV=$1
BU_SYS_EXCLUDE="/home/m1arkust/Programming/Bash/Training/MT_rsync_system_excludes"


# the help text will be shown in case the user uses the -h option
help_text="
Usage:
$0  /dev/sdxY  

(Where /dev/sdxY is replaced with the partition on
the external drive where the backup copy will reside.)

See rsync_system_excludes for the list of exclusions.
" 

while getopts h option
do
case $option in
                h) echo "$help_text" ;
                   exit 0
        esac
done

# Functions: check_root; check_exit
function check_root {
if [[ $(id -u) -ne 0 ]]
then
    echo "
    rerun as root"
    echo 
    exit 0
fi
}


function check_exit {
if  [[ $? -ne 0 ]]
then
    echo "
    An error occured"
    echo
    exit 0
fi 
}  


function ask_for {
echo -n "
    You want to go on? (answer yes or no): "
read answer
if [[ $answer = yes ]] || [[ $anwser = y ]]  || [[ $answer = Yes ]] || [[ $answer = Y ]] 
then
    echo "
    Ok, we will move on."
    echo
else
    echo "
    Your answer has not been yes.
    Script will die now."
    echo 
    if $(df | grep -q $BU_DEV) 
    then
        umount "$BU_DEV" 
    fi
    exit 0 
fi
}


# Tests 

check_root


#check if the parameter for mounting the  device is added
if ! [[ $# -eq 1 ]]
then
    echo "
    You missed to add the (backup-)device which is  to be mounted. Do it now:
    Here is the actual output of \"fdisk -l \" " 
    sleep 3 
    fdisk -l
    echo -n "which one, full name, like /dev/sdx? "
    read BU_DEV
fi

#  check if it is a valid device:
if ! [[ -b $BU_DEV ]]
then
    echo "
    You did not add a valid device. Start over"
    exit 0
fi 

# create BU_MP if necessary

if ! [[ -d $BU_MP ]] 
then
    mkdir "$BU_MP" 
fi 
 
 
# make sure the backup device isn't
# already mounted, then mount it.

if $(df | grep -q $BU_DEV)
then
    umount "$BU_DEV"
fi


# go for it:
echo "
    We will mount $BU_DEV on $BU_MP "
   
ask_for 


mount "$BU_DEV" "$BU_MP"

echo "
    Contents of "$BU_MP" 
    "
ls "$BU_MP"

echo -n "
    We will run rsync now? 
    "
ask_for



# run the backup

rsync -auvx --exclude-from="$BU_SYS_EXCLUDE"  --delete-after / "$BU_MP"
check_exit

# final info
echo "
    Rsync did finish, here is the actual content of "$BU_MP" 
    "
ls "$BU_MP"
echo "
    If it is wrong you are on your own. 
    "
echo "
    Please wait while "$BU_MP" is unmounted.
    "
umount "$BU_MP"

echo "
    Bye
    "

exit 0

