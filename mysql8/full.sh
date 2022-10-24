#!/bin/bash

full_backup() {
        /bin/bash /opt/scripts/backup/backup_validation.sh > $LOG_DIR/validation_before_backup.sh
        if [ ! -d $BACKUP_DIR ]
        then
            mkdir -p $BACKUP_DIR
        fi

        rm -rf $BACKUP_DIR/*
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Cleanup the backup folder is done! Starting backup" >> $LOG_DIR/xtrabackup.log
        xtrabackup --backup $USEROPTIONS  --compress --parallel=3 --compress-threads=3 --target-dir=$BACKUP_DIR/FULL > $TMPFILE 2>&1
	
	if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ]
	then
  		echo -e "\033[0;31mxtrabackup failed:\033[0m"; echo
  		echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Full Backup Failed!" >> $LOG_DIR/xtrabackup.log
  		rm -f $TMPFILE
		FULL_BACKUP_STATUS=1
		echo "mysql_full_backup_status $FULL_BACKUP_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/full_mysql_backup/instance/$HOSTNAME
  		exit 1
	else
		echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Full Backup Done!" >> $LOG_DIR/xtrabackup.log
                THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPFILE`
		echo -e "\033[0;32mDatabases backed up successfully to: $THISBACKUP\033[0m"
                rm -f $TMPFILE
        	FULL_BACKUP_STATUS=0
		echo "mysql_full_backup_status $FULL_BACKUP_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/full_mysql_backup/instance/$HOSTNAME
	fi
}
