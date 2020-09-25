#!/bin/bash
SLEEP=1
DB=zabbix

echo "
history
history_uint
history_str
history_text
history_log
trends
trends_uint
" | 
grep -v "^$" | \
while IFS= read -r TABLE
do {

OLD=$(echo $TABLE|sed "s|$|_old|")
TMP=$(echo $TABLE|sed "s|$|_tmp|")

# do not distract environment while optimizing
echo "RENAME TABLE $TABLE TO $OLD;"
echo "CREATE TABLE $TABLE LIKE $OLD;"

PART_LIST=$(
mysql $DB -e " \
SHOW CREATE TABLE $TABLE\G
" | \
grep -oP 'PARTITION \Kp[0-9_]+')
if [ -z "$PART_LIST" ] 
then
echo "OPTIMIZE TABLE $OLD;"
else
PARTITIONS=$(echo "$PART_LIST" | sed "s|$|,|" | tr -cd "[:print:]" | sed "s|.$||")
echo "ALTER TABLE $OLD REORGANIZE PARTITION $PARTITIONS"
fi

echo "RENAME TABLE $TABLE TO $TMP; RENAME TABLE $OLD TO $TABLE;"
echo "INSERT IGNORE INTO $TABLE SELECT * FROM $TMP;"
echo "DROP TABLE $TMP;"
echo

} done

