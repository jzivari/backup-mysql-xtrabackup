#!/bin/bash

incremental_backup() {
        if [ ! -d $BACKUP_DIR/FULL ]
        then
                echo "ERROR: Unable to find the FULL Backup. aborting....."
                exit -1
        fi

        if [ ! -f $BACKUP_DIR/last_incremental_number ]; then
            NUMBER=1
        else
            NUMBER=$(($(cat $BACKUP_DIR/last_incremental_number) + 1))
        fi

        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Starting Incremental backup $NUMBER" >> $LOG_DIR/xtrabackup.log
        if [ $NUMBER -eq 1 ]
        then
                xtrabackup --backup $USEROPTIONS   --parallel=3 --compress-threads=3 --target-dir=$BACKUP_DIR/inc$NUMBER --incremental-basedir=$BACKUP_DIR/FULL > $TMPFILE 2>&1
        else
                xtrabackup --backup $USEROPTIONS   --parallel=3 --compress-threads=3 --target-dir=$BACKUP_DIR/inc$NUMBER --incremental-basedir=$BACKUP_DIR/inc$(($NUMBER - 1)) > $TMPFILE 2>&1
        fi

        echo $NUMBER > $BACKUP_DIR/last_incremental_number
        if [ -z "`tail -1 $TMPFILE | grep 'completed OK!'`" ]
        then
                echo -e "\033[0;31mxtrabackup failed:\033[0m"; echo
                echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Incremental Backup:$NUMBER Failed!" >> $LOG_DIR/xtrabackup.log
                rm -f $TMPFILE
		INC_BACKUP_STATUS=1
		echo "mysql_incremental_"$NUMBER"_backup_status $INC_BACKUP_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/incremental_mysql_backup/instance/$HOSTNAME
                exit 1
        else
                echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Incremental Backup:$NUMBER Done!" >> $LOG_DIR/xtrabackup.log
		THISBACKUP=`awk -- "/Backup created in directory/ { split( \\\$0, p, \"'\" ) ; print p[2] }" $TMPFILE`
		echo -e "\033[0;32mDatabases backed up successfully to: $THISBACKUP\033[0m"
                rm -f $TMPFILE
		INC_BACKUP_STATUS=0
		echo "mysql_incremental_"$NUMBER"_backup_status $INC_BACKUP_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/incremental_mysql_backup/instance/$HOSTNAME
        fi

}
