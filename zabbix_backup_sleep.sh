#!/bin/bash
SLEEP=10

mysqldump \
--flush-logs \
--single-transaction \
--create-options \
--no-data \
zabbix > schema.sql
echo "sleeping for $SLEEP seconds"
sleep $SLEEP

mysqldump \
--flush-logs \
--single-transaction \
--no-create-info \
--ignore-table=history \
--ignore-table=history_log \
--ignore-table=history_str \
--ignore-table=history_text \
--ignore-table=history_uint \
--ignore-table=trends \
--ignore-table=trends_uint \
zabbix > data.sql
sleep $SLEEP

echo "
history
history_uint
history_str
history_text
history_log
trends
trends_uint
" | grep -v "^$" | while IFS= read -r table; do {
echo $table
mysql --flush-logs --single-transaction --no-create-info zabbix $table > $table.sql
echo "sleeping for $SLEEP seconds"
sleep $SLEEP
} done

