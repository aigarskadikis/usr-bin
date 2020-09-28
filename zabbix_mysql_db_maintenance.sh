#!/bin/bash

date

DB=zabbix
DEST=/backup/mysql/zabbix/raw
FROM=0
TO=0

echo "
history_str
history_log
history_text
trends_uint
trends
history
history_uint
" | 
grep -v "^$" | \
while IFS= read -r TABLE
do {

OLD=$(echo $TABLE|sed "s|$|_old|")
TMP=$(echo $TABLE|sed "s|$|_tmp|")

# do not distract environment while optimizing
echo "RENAME TABLE $TABLE TO $OLD;"
mysql $DB -e "RENAME TABLE $TABLE TO $OLD;"
echo "CREATE TABLE $TABLE LIKE $OLD;"
mysql $DB -e "CREATE TABLE $TABLE LIKE $OLD;"

PART_LIST_DETAILED=$(
mysql $DB -e " \
SHOW CREATE TABLE $TABLE\G
" | \
grep -Eo "PARTITION.*VALUES LESS THAN..[0-9]+"
)


if [ -z "$PART_LIST_DETAILED" ] 
then

# reset FROM counter to year 1970
FROM=0

# if table does not have partitions then optize whole table
echo "OPTIMIZE TABLE $OLD;"
mysql $DB -e "OPTIMIZE TABLE $OLD;"

# do mysqldump of whole table
mysqldump --set-gtid-purged=OFF --flush-logs --single-transaction --no-create-info \
$DB $OLD | gzip --fast > $DEST/$(date -d @$FROM "+%Y%m%d").$OLD.sql.gz

else
# if table contains partitions

# observe partition name and timestamps
echo "$PART_LIST_DETAILED" | \
grep -Eo "PARTITION.*VALUES LESS THAN..[0-9]+" | \
grep -v "^$" | \
while IFS= read -r LINE
do {

# name of partition
PARTITION=$(echo "$LINE" | grep -oP "PARTITION.\K\w+")

# rebuild partition, this will really free up free space if some records do not exist anymore
echo "ALTER TABLE $OLD REBUILD PARTITION $PARTITION;"
mysql $DB -e "ALTER TABLE $OLD REBUILD PARTITION $PARTITION;"

# LINE
echo $LINE
# timestamp from
FROM=$TO
echo FROM=$FROM
# timestamp to
TO=$(echo "$LINE" | grep -Eo "[0-9]+$")
echo TO=$TO

mysqldump \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--no-create-info \
--where=" clock >= $FROM AND clock < $TO " \
$DB $OLD | gzip --fast > $DEST/$(date -d @$FROM "+%Y%m%d").$OLD.sql.gz

} done

fi

echo "RENAME TABLE $TABLE TO $TMP; RENAME TABLE $OLD TO $TABLE;"
mysql $DB -e "RENAME TABLE $TABLE TO $TMP; RENAME TABLE $OLD TO $TABLE;"

echo "SET SESSION SQL_LOG_BIN=0; INSERT IGNORE INTO $TABLE SELECT * FROM $TMP;"
mysql $DB -e "SET SESSION SQL_LOG_BIN=0; INSERT IGNORE INTO $TABLE SELECT * FROM $TMP;"

echo "DROP TABLE $TMP;"
mysql $DB -e "DROP TABLE $TMP;"

echo

} done

/usr/sbin/zabbix_server -R housekeeper_execute

