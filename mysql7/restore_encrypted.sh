restore_encrypted()
{
    array=()
    cd $LOCAL_BACKUP_DIR
    for i in `ls *.tar.enc | cut -d'.' -f1`
    do
        array+=("$i")
    done
    echo "These encrypted backups are available.Which one do you prefer to restore?(Timeout 1min)"
    for i in "${!array[@]}"
    do
        printf "%s\t%s\n" "$i" "${array[$i]}"
    done
    read -t 5 USER_INPUT
    if [ -z "$USER_INPUT" ]
    then
	USER_INPUT="${array[-1]}"
    else
	USER_INPUT="${array[$USER_INPUT]}"
    fi
    echo "Selected backup for restore is: $USER_INPUT"
    ##########
    LOG_DIR_RESTORE=/var/log/mysql/backup-script/$USER_INPUT
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": starting restore to $TARGET_SERVER" >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": starting decrypt." >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    openssl aes-256-cbc -d -a -pbkdf2 -in $USER_INPUT.tar.enc -out $USER_INPUT.tar -pass pass:****
    tar -xvf $USER_INPUT.tar
    rm -rf $USER_INPUT.tar
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": decryption DONE." >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing the FULL backup" >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    xtrabackup --decompress --remove-original --parallel=4 --target-dir=$USER_INPUT/FULL
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing Done !!!" >> $LOG_DIR_RESTORE/xtrabackup-restore.log

    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing FULL Backup ..." >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    xtrabackup --prepare  --apply-log-only --target-dir=$USER_INPUT/FULL
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": FULL Backup Preparation Done!!!" >> $LOG_DIR_RESTORE/xtrabackup-restore.log

    P=`find $USER_INPUT -iname "inc*" | wc -l`
    for (( i=1; i<=$P; i++ ))
    do
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$i" >> $LOG_DIR_RESTORE/xtrabackup-restore.log
        xtrabackup --decompress  --remove-original --parallel=4 --target-dir=$USER_INPUT/inc$i
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Decompressing incremental:$i Done." >> $LOG_DIR_RESTORE/xtrabackup-restore.log

        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Prepareing incremental:$i"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
        if [ $i == $P ]
            then
                xtrabackup --prepare  --target-dir=$USER_INPUT/FULL --incremental-dir=$USER_INPUT/inc$i
                echo `date '+%Y-%m-%d %H:%M:%S:%s'`": incremental:$i LAST incremental Preparation Done !!!" >> $LOG_DIR_RESTORE/xtrabackup-restore.log
                continue
        fi
        xtrabackup --prepare  --apply-log-only --target-dir=$USER_INPUT/FULL --incremental-dir=$USER_INPUT/inc$i
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": incremental:$i Preparation Done." >> $LOG_DIR_RESTORE/xtrabackup-restore.log

    done
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Stop mysql on target server"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    ssh root@$TARGET_SERVER "systemctl stop mysql.service"
    ssh root@$TARGET_SERVER "rm -rf /var/lib/mysql/*"
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": Starting rsync to target server"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    rsync  -auv  $USER_INPUT/FULL/ root@$TARGET_SERVER:/var/lib/mysql/
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": rsync to target server Done !!!"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    ssh root@$TARGET_SERVER "chown -R mysql:mysql /var/lib/mysql/"
    ssh root@$TARGET_SERVER "systemctl start mysql.service"
    if [ $? == 0 ]
    then
        DR_RESTORE_STATUS=0
        echo "dr_restore_status $DR_RESTORE_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/dr_restore_status/instance/$HOSTNAME
        rm -rf $USER_INPUT
    else
        DR_RESTORE_STATUS=1
        echo "dr_restore_status $DR_RESTORE_STATUS" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/dr_restore_status/instance/$HOSTNAME
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": restore failed!!!"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
        exit
    fi
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": start mysql on target server. resore completed. Done !!!"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    #check validation
    echo `date '+%Y-%m-%d %H:%M:%S:%s'`": start validation check"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    ssh root@$TARGET_SERVER 'bash -s' < /opt/scripts/backup/backup_validation.sh > $LOG_DIR_RESTORE/validation_after_restore.sh
    diff $LOG_DIR_RESTORE/validation_before_backup.sh $LOG_DIR_RESTORE/validation_after_restore.sh
    if [ $? == 0 ]
    then
        echo "dr_validation_status 0" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/dr_validation_status/instance/$HOSTNAME
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": validation Done!!!"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
    else
        echo "dr_restore_status 1" | curl --data-binary @- http://10.198.15.204:9091/metrics/job/dr_restore_status/instance/$HOSTNAME
        echo `date '+%Y-%m-%d %H:%M:%S:%s'`": validation failed!!!"  >> $LOG_DIR_RESTORE/xtrabackup-restore.log
        exit
    fi
}
