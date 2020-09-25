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
mysql $DB -e " \
SHOW CREATE TABLE $TABLE\G
" | \
grep -oP 'PARTITION \Kp[0-9_]+'
} done

