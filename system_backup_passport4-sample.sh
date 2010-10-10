#!/usr/bin/env bash
# system_backup_passport.sh
# version 4
# Back up OS to encrypted partition on external drive
# Create gpg-encrypted archive on another internal drive


# NOTES:
# This version is set to create the archive on a
# luks-encrypted LVM partition (sda3) instead of 
# the unencrypted partition (sdb1) used in version 3.
# Also, this version was reorganized so that the archive
# drive does not get mounted unless you say you want the archive created.

# This is currently set to back up /etc for testing purposes. ####
# To back up the system, edit the rsync command from "/etc" to "/"
# and the TAR_FILE variable to say "_OS_" instead of "_etc_" (or name it however you want).
# and make the script executable.

# To use a different drive/partition (not my 120G WD Passport, second partition)
# change the uuid in the BU_DEV variable. (in Lenny, you can use disk labels, 
# but in Squeeze, blkid won't show the disk label on an encrypted partition.)


# VARIABLES - set these to suit your needs

# Path to the rsync excludes file
BU_SYS_EXCLUDE="/path/to/rsync_system_excludes"  #########

# Partition that holds the archive directory ($ARCHIVE_DIR)
# Don't use a full device node here. It also gets used
# for the mount point. In my case, sdb1 gets mounted at
# /mnt/sdb1 during boot, so it's unlikely that this will need mounting.
# If the mount point doesn't exist, the mount command will complain,
# and the script will exit.
#ARCHIVE_DEV="sdb1"
ARCHIVE_DEV="sda3"

# Path to the directory to store the encrypted archive
#ARCHIVE_DIR="/mnt/$ARCHIVE_DEV/files/backups/archives"
ARCHIVE_DIR="/media/mapper_vol0-datapart/backups" #######

# Location/name of the archive file
TAR_FILE="$ARCHIVE_DIR/backup_$(hostname)_etc_$(date +%Y-%m-%d).tar.gz"

# The encrypted drive/partition which will hold the rsync'd backup:
# The long string of numbers is the UUID of the correct partition,
# and is the only part of this you should change.
# WD Passport:
BU_DEV="$(/sbin/blkid | awk -F ":" '/50123414-81f0-4e65-97d0-0019ceb2e210/ { print $1 }')"

# Label for the encrypted drive/partition to be used by cryptsetup and /dev/mapper
# and also used for the partition's mount point. If /mnt/$LABEL doesn't exist, the mount
# command will give an appropriate error.
LABEL="passport"
LABEL2="lenny"

# LVM Volume (the VG Name dsplayed by lvdisplay
# or pvdisplay after opening the encrypted partition.)
VG_NAME="vol0"

# LVM Logical Partition (the last part of the LV Name 
# displayed by lvdisplay after opening the encrypted partition.)
LV_NAME="datapart"

clear; date
echo 


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
    exit 1
fi 
}

function unmount_external {
	umount /mnt/$LABEL
    cryptsetup luksClose /dev/mapper/$LABEL
}

function unmount_archive_dev {
	umount /media/mapper_$VG_NAME-$LV_NAME
    vgchange -a n $VG_NAME
    cryptsetup luksClose $LABEL2
}

check_root


# check if encrypted backup drive is mounted, or mount the drive by UUID.
if ! $(df | grep -q "/dev/mapper/$LABEL")
then
    cryptsetup luksOpen "$BU_DEV" "$LABEL"
    mount /dev/mapper/$LABEL /mnt/$LABEL
    check_exit
    echo "
        Backup drive is now mounted.
        "
fi

echo "
    Contents of backup drive:
    "
ls /mnt/$LABEL

while true ; do
    echo "
    Ready to run rsync now. Continue? (y,n)
    "
    read answer
    case "$answer" in
      [Nn]*) unmount_external ; echo "
        Exiting the script now...
        " ; exit 0 ;;
      [Yy]*) break ;;
    esac
done
   
# run rsync
rsync -auvx --delete-after --exclude-from="$BU_SYS_EXCLUDE"   /etc /mnt/$LABEL
check_exit
echo "
    Rsync is finished.
    Contents of backup drive:
    "
    ls /mnt/$LABEL


# Ask if a tarred, encrypted, date-stamped archive is desired.

while true ; do
    echo -n "
    Would you like a date-stamped and encrypted archive
    to be created at $TAR_FILE.gpg?
    (y/n)
    "
read answer
    case "$answer" in
      [Nn]*) unmount_external ; check_exit ; echo "
        Exiting the script now...
        " ; exit 0 ;;
      [Yy]*) break ;;
    esac
done
 
# mount the archive drive if it's not already mounted
if ! $(df | grep -q "/dev/mapper/$VG_NAME-$LV_NAME")
    then
    cryptsetup luksOpen /dev/$ARCHIVE_DEV $LABEL2
    vgchange -a y "$VG_NAME"
    mount /dev/mapper/$VG_NAME-$LV_NAME  /media/mapper_$VG_NAME-$LV_NAME
    check_exit
fi

printf  "\n Contents of archive directory:\n"
ls "$ARCHIVE_DIR"
# WARNING! Sometimes the numbers change. Don't know why. #############
#df -h | awk -v pattern=$ARCHIVE_DEV '$0 ~ pattern { print "    " $4 " " "Avail." "    " "("$5")" " " "Used" }'
#df -h | awk -v pattern=$LV_NAME '$0 ~ pattern { print $0 }'
#df -h | awk '/datapart/ { print "    " $4 " " "Avail." "    " $5 " " "Used" }'
df -h | awk -v pattern=$LV_NAME '$0 ~ pattern { print "    " $3 " " "Avail." "    " $4 " " "Used"  }'

while true ; do
    echo -n "
    Make sure you have enough space to create the archive. 
    Continue?  (y/n)
    "
    read answer
    case "$answer" in
      [Nn]*) echo "
        Nothing will be unmounted.
        Exiting the script now...
        " ; exit 0 ;;
      [Yy]*) break ;;
    esac
done

tar -czf  $TAR_FILE  /dev/mapper/$LABEL  
gpg -c $TAR_FILE 
rm $TAR_FILE 
echo "
     Encrypted archive was created.
           
         " 
    ls "$ARCHIVE_DIR"    
    

echo "
     
    "
while true ; do
echo -n " Ready to exit. Please choose:
    
    (a) unmount the external drive, but leave the archive drive mounted
    (b) unmount the archive drive, but leave the external drive mounted
    (c) unmount both the external and archive drives
    (d) leave both drives mounted
    "    
    read answer
    echo "
    Please wait...
    "
    case "$answer" in
        [Aa]*) unmount_external ; break ;;
        [Bb]*) unmount_archive_dev ;  break ;;
        [Cc]*) unmount_external ; unmount_archive_dev ; break ;;
        [Dd]*) break ;;
    esac
done

echo "
Bye!
"

exit 0




