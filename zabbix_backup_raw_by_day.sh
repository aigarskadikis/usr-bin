#!/bin/bash
SLEEP=1
DB=zabbix

d=0

while true
do {

# add +1
d=$((d+1))

# calculate time the backup should be made of
FROM=$(date -d "$((d+1)) DAY AGO" "+%Y-%m-%d")
TILL=$(date -d "$((d+0)) DAY AGO" "+%Y-%m-%d")

echo "
history
history_uint
history_str
history_text
history_log
trends
trends_uint
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {

# check if this day is already in backup
if [ -f $FROM.$TILL.$TABLE.sql ]; then

echo $FROM.$TILL.$TABLE.sql already exist

else

echo "$TABLE $FROM 00:00:00(inclusive) => $TILL 00:00:00(exclusive)"
mysqldump --flush-logs \
--single-transaction \
--no-create-info \
--where=" \
clock >= UNIX_TIMESTAMP(\"$(date -d "$((d+1)) DAY AGO" "+%Y-%m-%d 00:00:00")\") \
AND \
clock < UNIX_TIMESTAMP(\"$(date -d "$((d+0)) DAY AGO" "+%Y-%m-%d 00:00:00")\") \
" \
$DB $TABLE > $TABLE.sql
mv $TABLE.sql $FROM.$TILL.$TABLE.sql
echo "sleeping for $SLEEP seconds"
sleep $SLEEP


fi

# end of TABLE loop
} done


# end of FROM => TILL loop
} done

