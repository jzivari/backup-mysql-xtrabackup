#!/bin/bash

encrypt()
{
	YESTERDAY_DATE=`date --date="1 days ago" +%Y-%m-%d`
	YESTERDAY_BACKUP_LOG_DIR="/var/log/mysql/backup-script/$YESTERDAY_DATE"
	cd $LOCAL_BACKUP_DIR
	echo "starting encryption" >>  $YESTERDAY_BACKUP_LOG_DIR/encryption.log
	tar -cvf $YESTERDAY_DATE.tar $YESTERDAY_DATE
	openssl enc -aes-256-cbc -a -salt -pbkdf2 -in $LOCAL_BACKUP_DIR/$YESTERDAY_DATE.tar -out $LOCAL_BACKUP_DIR/$YESTERDAY_DATE.tar.enc -pass pass:****	
	if  [ $? == 0 ] 
	    then
	        echo "encryption Done" >> $YESTERDAY_BACKUP_LOG_DIR/encryption.log
		rm -rf  $YESTERDAY_DATE $YESTERDAY_DATE.tar
		ENCRYPTION_BACKUP_STATUS=0
		echo "mysql_encryption_backup_status $ENCRYPTION_BACKUP_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/encryption_mysql_backup/instance/$HOSTNAME
		exit 0
	    else
	        echo "encryption failed!" >> $YESTERDAY_BACKUP_LOG_DIR/encryption.log
		rm -rf $YESTERDAY_DATE.tar.enc $YESTERDAY_DATE.tar
		ENCRYPTION_BACKUP_STATUS=1
		echo "mysql_encryption_backup_status $ENCRYPTION_BACKUP_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/encryption_mysql_backup/instance/$HOSTNAME
		exit 1
	fi
}
