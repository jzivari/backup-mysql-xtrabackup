#!/bin/bash

rotate()
{
	#CLEAN_DATE=`date --date="10 days ago" +%Y-%m-%d`
	find $LOCAL_BACKUP_DIR/ -maxdepth 1 ! -newermt $CLEAN_DATE | xargs rm -rf
}
