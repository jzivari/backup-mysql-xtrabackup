#!/bin/bash
#Import other scripts to the main script
source /opt/scripts/backup/full.sh
source /opt/scripts/backup/incremental.sh
source /opt/scripts/backup/restore.sh
source /opt/scripts/backup/restore_encrypted.sh
source /opt/scripts/backup/encrypt.sh
source /opt/scripts/backup/rotate.sh
source /opt/scripts/backup/mysql_files_backup.sh

## Full and Incremental variables
TMPFILE="/tmp/xtrabackup-runner.$$.tmp"
USEROPTIONS="--user=backup --password=****"
BACKUP_DIR=/backup/mysql/mysql8/production-mysql/$HOSTNAME/$(date +\%Y-\%m-\%d)
LOG_DIR=/var/log/mysql/backup-script/$(date +\%Y-\%m-\%d)
LOCAL_BACKUP_DIR="/backup/mysql/mysql8/production-mysql/$HOSTNAME"

##Restore
#CURRENT_DAY=`date --date="6 days ago" +%Y-%m-%d`
CURRENT_DAY=`date +%Y-%m-%d`
TARGET_SERVER=192.168.1.11

##Rotation
CLEAN_DATE=`date --date="10 days ago" +%Y-%m-%d`

#Handle log features
if [ ! -d $LOG_DIR ]
   then
     mkdir -p $LOG_DIR
fi

#Usage function
usage() { 
	echo
        echo -e "\033[0;32mUsage: $(basename $0) [option] \033[0m"
	echo
        echo -e "\033[0;32mfull\033[0m Perform Full Backup"
        echo -e "\033[0;32mincremental\033[0m Perform Incremental Backup"
        echo -e "\033[0;32mrestore\033[0m Start restoring current day backup"
        echo -e "\033[0;32mrestore_encrypted\033[0m Start restoring current day backup"
        echo -e "\033[0;32mencrypt\033[0m Start encrypt yesterday backup"
        echo -e "\033[0;32mbackup-mysql-files\033[0m Start encrypt yesterday backup"
        echo -e "\033[0;32mhelp\033[0m show this help"
}
if [ $# -eq 0 ]
   then
     usage
     exit 1
fi


#Exucute
    case $1 in
        "full")
            full_backup
            ;;
        "incremental")
        incremental_backup
            ;;
        "restore_encrypted")
        restore_encrypted
            ;;
	"restore")
	restore
	    ;;
	"rotate")
	rotate
	    ;;
	"encrypt")
	encrypt
	    ;;
	"files-backup")
	backup_mysql_files
	    ;;
        "help")
         usage
         break
            ;;
        *) echo "invalid option";;
    esac
