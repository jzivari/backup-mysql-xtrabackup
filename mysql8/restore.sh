full_preparation()
{
        cd $LOCAL_BACKUP_DIR/$CURRENT_DAY
	echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing the FULL backup" >> $LOG_DIR/xtrabackup-restore.log
        xtrabackup --decompress --remove-original --parallel=4 --target-dir=FULL
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing Done !!!" >> $LOG_DIR/xtrabackup-restore.log
	echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing FULL Backup ..." >> $LOG_DIR/xtrabackup-restore.log
        xtrabackup --prepare  --apply-log-only --target-dir=FULL
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": FULL Backup Preparation Done!!!" >> $LOG_DIR/xtrabackup-restore.log

}

restore()
{
    array=()
    cd $LOCAL_BACKUP_DIR/$CURRENT_DAY
    for i in `ls | grep -v "last_incremental_number"`
    do
	array+=("$i")
    done
    echo -e "\033[0;32mAvailable backups for today is: $CURRENT_DAY. Select your number(default is last incremental backup!!) \033[0m"
    for i in "${!array[@]}"
    do
        printf "%s\t%s\n" "$i" "${array[$i]}"
    done
    read -t 5 USER_INPUT
    USER_INPUT_VALUE="${array[$USER_INPUT]}"
    ARRAY_LENGTH=${#array[@]}
    ARRAY_LENGTH_INCS=$((ARRAY_LENGTH - 1))
    if [ -z "$USER_INPUT" ]
    then
        USER_INPUT="${array[-1]}"
        echo "Selected backup for restore is: $USER_INPUT"
	sleep 5
        full_preparation
	P=`find . -iname "inc*" | wc -l`
	for (( i=1; i<=$P; i++ ))
        do
             echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$i" >> $LOG_DIR/xtrabackup-restore.log
             xtrabackup --decompress  --remove-original --parallel=4 --target-dir=inc$i
             echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$i Done." >> $LOG_DIR/xtrabackup-restore.log

             echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing incremental:$i"  >> $LOG_DIR/xtrabackup-restore.log
             if [ $i == $P ]
             then
              xtrabackup --prepare  --target-dir=FULL --incremental-dir=inc$i
              echo `date '+%Y-%m-%d %H:%M:%S:%s'`": incremental:$i LAST incremental Preparation Done !!!" >> $LOG_DIR/xtrabackup-restore.log
              continue
             fi
              xtrabackup --prepare  --apply-log-only --target-dir=FULL --incremental-dir=inc$i
              echo `date '+%Y-%m-%d %H:%M:%S:%s'`": incremental:$i Preparation Done." >> $LOG_DIR/xtrabackup-restore.log
        done
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Stop mysql on target server"  >> $LOG_DIR/xtrabackup-restore.log
        ssh root@$TARGET_SERVER "systemctl stop mysql.service"
        ssh root@$TARGET_SERVER "rm -rf /var/lib/mysql/*"
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Starting rsync to target server"  >> $LOG_DIR/xtrabackup-restore.log
        rsync  -auv  FULL/ root@$TARGET_SERVER:/var/lib/mysql/
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": rsync to target server Done !!!"  >> $LOG_DIR/xtrabackup-restore.log
        ssh root@$TARGET_SERVER "chown -R mysql:mysql /var/lib/mysql/"
        ssh root@$TARGET_SERVER "systemctl start mysql.service"
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": start mysql on target server. resore completed. Done !!!"  >> $LOG_DIR/xtrabackup-restore.log
    elif [ "$USER_INPUT" == 0 ]
	then
	  echo "phase full"
	  sleep 5
	  full_preparation
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Stop mysql on target server"  >> $LOG_DIR/xtrabackup-restore.log
          ssh root@$TARGET_SERVER "systemctl stop mysql.service"
          ssh root@$TARGET_SERVER "rm -rf /var/lib/mysql/*"
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Starting rsync to target server"  >> $LOG_DIR/xtrabackup-restore.log
          rsync  -auv  FULL/ root@$TARGET_SERVER:/var/lib/mysql/
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": rsync to target server Done !!!"  >> $LOG_DIR/xtrabackup-restore.log
          ssh root@$TARGET_SERVER "chown -R mysql:mysql /var/lib/mysql/"
          ssh root@$TARGET_SERVER "systemctl start mysql.service"
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": start mysql on target server. resore completed. Done !!!" >> $LOG_DIR/xtrabackup-restore.log
    elif [  "$USER_INPUT" != 0 ] && [ "$USER_INPUT" -le "$ARRAY_LENGTH_INCS" ] 
        then
          full_preparation
          for (( i=1; i<=$USER_INPUT; i++ ))
          do
	     echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$i" >> $LOG_DIR/xtrabackup-restore.log
             xtrabackup --decompress  --remove-original --parallel=4 --target-dir=inc$i
             echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$i Done." >> $LOG_DIR/xtrabackup-restore.log
             echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing incremental:$i"  >> $LOG_DIR/xtrabackup-restore.log
	     if [ $i == $USER_INPUT ]
             then
              xtrabackup --prepare  --target-dir=FULL --incremental-dir=inc$i
              echo `date '+%Y-%m-%d %H:%M:%S:%s'`": incremental:$i LAST incremental Preparation Done !!!" >> $LOG_DIR/xtrabackup-restore.log
              continue
             fi
              xtrabackup --prepare  --apply-log-only --target-dir=FULL --incremental-dir=inc$i
              echo `date '+%Y-%m-%d %H:%M:%S:%s'`": incremental:$i Preparation Done." >> $LOG_DIR/xtrabackup-restore.log
          done
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Stop mysql on target server"  >> $LOG_DIR/xtrabackup-restore.log
          ssh root@$TARGET_SERVER "systemctl stop mysql.service"
          ssh root@$TARGET_SERVER "rm -rf /var/lib/mysql/*"
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Starting rsync to target server"  >> $LOG_DIR/xtrabackup-restore.log
          rsync  -auv  FULL/ root@$TARGET_SERVER:/var/lib/mysql/
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": rsync to target server Done !!!"  >> $LOG_DIR/xtrabackup-restore.log
          ssh root@$TARGET_SERVER "chown -R mysql:mysql /var/lib/mysql/"
          ssh root@$TARGET_SERVER "systemctl start mysql.service"
          echo `date '+%Y-%m-%d %H:%M:%S:%s'`": start mysql on target server.resore completed. Done !!!"  >> $LOG_DIR/xtrabackup-restore.log
    else
	  echo "Out of Range.Error!!!"
    fi
}
