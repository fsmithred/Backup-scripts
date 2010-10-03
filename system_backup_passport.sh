#!/usr/bin/env bash
# system_backup_passport.sh
# Back up OS to encrypted partition on external drive
# Create encrypted archive on another internal drive
# fsmithred October 3, 2010


# NOTES:
#### This is currently set to back up /etc for testing purposes. ####
# To back up the system, edit the rsync command from "/etc" to "/"
#  and the TAR_FILE variable to say "_OS_" instead of "_etc_" (or name it however you want).
# To use a different drive/partition (not my 120G WD Passport, second partition)
# change the uuid in the BU_DEV variable. (in Lenny, you can use disk labels, 
# but in Squeeze, blkid won't show the disk label on an encrypted partition.)


# VARIABLES - set these to suit your needs

# Path to the rsync excludes file
BU_SYS_EXCLUDE="/path-to/rsync_system_excludes"

# Partition that holds the archive directory ($ARCHIVE_DIR)
# Don't use a full device node here. It also gets used 
# for the mount point. In my case, sdb1 gets mounted at 
# /mnt/sdb1 during boot, so it's unlikely that this will need mounting.
# If the mount point doesn't exist, the mount command will complain,
# and the script will exit.
ARCHIVE_DEV="sdb1"

# Path to the directory to store the encrypted archive
ARCHIVE_DIR="/mnt/$ARCHIVE_DEV/files/backups/archives"

# Location/name of the archive file
TAR_FILE="$ARCHIVE_DIR/backup_$(hostname)_etc_$(date +%Y-%m-%d).tar.gz"

# The encrypted drive/partition which will hold the rsync'd backup:
# The long string of numbers is the UUID of the correct partition,
# and is the only part of this you should change.
BU_DEV="$(/sbin/blkid | awk -F ":" '/50123414-81f0-4e65-97d0-0019ceb2e210/ { print $1 }')"

# Label for the encrypted drive/partition to be used by cryptsetup and /dev/mapper
# and also used for the partition's mount point. If /mnt/$LABEL doesn't exist, the mount
# command will give an appropriate error.
LABEL="passport"

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


check_root


# check if encrypted backup drive is mounted, or mount the drive by UUID.
if $(df | grep -q "/dev/mapper/$LABEL")
then
    echo "
        Backup drive is mounted.
        "
else
    cryptsetup luksOpen "$BU_DEV" "$LABEL"
    mount /dev/mapper/$LABEL /mnt/$LABEL
    check_exit
    echo "
        Backup drive is now mounted.
        "
fi

echo "Contents of backup drive:"
ls /mnt/$LABEL


# check if drive to hold archive is mounted, or mount it.
if $(df | grep -q "/dev/$ARCHIVE_DEV")
then
    echo "
        Archive drive is mounted
    "
else
    mount /dev/$ARCHIVE_DEV /mnt/$ARCHIVE_DEV
    check_exit
    echo "Archive drive is now mounted"
fi

echo -n "Contents of archive directory:"
ls -lh "$ARCHIVE_DIR"
df -h | awk -v pattern=$ARCHIVE_DEV '$0 ~ pattern { print $4 "  "  "("$5")" "  " "available space on the partition" }'

echo -n "
    Would you like to run rsync now? (y/n)
    "
read answer
case ${answer:0:1} in
    [Yy]) echo "ok" ;;
    [Nn]) echo "
        Check the code.
        Unmount anything that needs to be unmounted.
        " 
                        exit 0 ;;
     * ) echo "
         Nothing has been done. Nothing has been unmounted.
         Have a break, pal
         " 
               exit 0
esac 


# run rsync
rsync -auvx --exclude-from="$BU_SYS_EXCLUDE"   /etc /mnt/$LABEL
check_exit
echo "
    Rsync is finished.
    Contents of backup drive:
    "
    ls /mnt/$LABEL


# Ask if a tarred, encrypted, date-stamped archive is desired.

echo -n "
    Would you like a date-stamped and encrypted archive
    to be created at $TAR_FILE.gpg?
    (y/N)
    "
read answer
case ${answer:0:1} in
    [Yy]) tar -czf  $TAR_FILE  /dev/mapper/$LABEL  
          gpg -c $TAR_FILE 
          rm $TAR_FILE 
          echo "
           Encrypted archive was created.
           
               " 
          ls "$ARCHIVE_DIR" ;;
       *) ;;
esac


echo "
     
    "
echo "
    Please wait while the external drive is unmounted.
    "
umount /mnt/$LABEL
cryptsetup luksClose /dev/mapper/$LABEL


echo "
    Bye
    "

exit 0
