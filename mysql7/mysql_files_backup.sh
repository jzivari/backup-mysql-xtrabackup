backup_mysql_files()
{
    DATE=`date +%Y-%m-%d`
    DATE_clean=`date --date="10 days ago" +%Y-%m-%d`
    MYSQL_DIR="/etc/mysql/"
    LOCAL_BACKUP_DIR="/backup/mysql/mysql7/os-files/slave-2/"
    tar -cvzf $LOCAL_BACKUP_DIR/$DATE.tar.gz  $MYSQL_DIR
    
    find $LOCAL_BACKUP_DIR/ -maxdepth 1 ! -newermt $DATE_clean | xargs rm -rf
}
