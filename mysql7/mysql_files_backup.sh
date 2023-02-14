backup_mysql_files()
{
    DATE=`date +%Y-%m-%d`
    DATE_clean=`date --date="10 days ago" +%Y-%m-%d`
    MYSQL_DIR="/etc/mysql/"
    OS_BACKUP_DIR="/backup/mysql/mysql7/os-files/$HOSTNAME/"
    if [ ! -d $OS_BACKUP_DIR ]
    then
        mkdir -p $OS_BACKUP_DIR
    fi

    tar -cvzf $OS_BACKUP_DIR/$DATE.tar.gz  $MYSQL_DIR
    
    find $OS_BACKUP_DIR/ -maxdepth 1 ! -newermt $DATE_clean | xargs rm -rf
}
