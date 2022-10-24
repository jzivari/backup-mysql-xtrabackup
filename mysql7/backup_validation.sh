#!/bin/bash
DB_HOST=127.0.0.1
DB_USER="root"
DB_PASS="****"
mysql -u$DB_USER -p$DB_PASS -e "SELECT schema_name FROM information_schema.schemata  where schema_name not in ('information_schema','mysql','performance_schema','sys');"  2>/dev/null 1> temp.txt
for i in `cat temp.txt`
do
	DB_COUNT=$(expr $DB_COUNT + 1)

	TABLE_COUNT=`mysql -u$DB_USER -p$DB_PASS -e "SELECT count(*)  AS TOTALTABLES FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '$i';" 2>/dev/null`
	SUM=`echo $TABLE_COUNT | awk '{ print $2 }'`
	SUM_TABLE=$(expr $SUM_TABLE + $SUM)

	TABLE_FIELD=`mysql -u$DB_USER -p$DB_PASS -e "SELECT COUNT(*) AS TOTAL_NUMBER_OF_FIELDS FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$i';" 2>/dev/null`
	SUM2=`echo $TABLE_FIELD | awk '{ print $2 }'`
	SUM_FIELD=$(expr $SUM_FIELD + $SUM2)
done
echo $DB_COUNT $SUM_TABLE $SUM_FIELD
rm temp.txt
