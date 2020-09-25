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
#echo table $TABLE
PART_LIST=$(
mysql $DB -e " \
SHOW CREATE TABLE $TABLE\G
" | \
grep -oP 'PARTITION \Kp[0-9_]+')
if [ -z "$PART_LIST" ] 
then
echo OPTIMIZE TABLE $TABLE;
else
echo ALTER TABLE $TABLE REORGANIZE PARTITION $(echo "$PART_LIST" | sed "s|$|,|" | tr -cd '[:print:]' | sed "s|.$||");
fi
} done

