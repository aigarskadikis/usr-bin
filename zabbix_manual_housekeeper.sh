#!/bin/bash

date

SLEEP=1
DB=zabbix

# items.value_type:
# 0, ITEM_VALUE_TYPE_FLOAT - Float
# 1, ITEM_VALUE_TYPE_STR - Character
# 2, ITEM_VALUE_TYPE_LOG - Log
# 3, ITEM_VALUE_TYPE_UINT64 - Unsigned integer
# 4, ITEM_VALUE_TYPE_TEXT - Text


HISTORY_PERIOD=$(
mysql $DB --raw --batch -N -e "
SELECT DISTINCT items.history
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status IN (0,1)
AND items.value_type=0
AND items.history LIKE '%d';
"
)

echo "$HISTORY_PERIOD" | \
grep -v "^$" | \
while IFS= read -r PERIOD
do {

PERIOD_FULL_NAME=$(echo "$PERIOD" | sed "s|d| DAY|")
echo $PERIOD
echo $PERIOD_FULL_NAME

# summary items which has this exact period
ALL_ITEM_IDS=$(
mysql $DB --raw --batch -N -e "
SET SESSION group_concat_max_len = 1000000;
SELECT GROUP_CONCAT(items.itemid)
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status IN (0,1)
AND items.value_type=0
AND items.history=\"$PERIOD\";
"
)

echo "DELETE FROM history 
WHERE itemid IN ($ALL_ITEM_IDS)
AND clock < UNIX_TIMESTAMP(NOW()-INTERVAL $PERIOD_FULL_NAME)
LIMIT 1;"
mysql $DB -e "DELETE FROM history 
WHERE itemid IN ($ALL_ITEM_IDS)
AND clock < UNIX_TIMESTAMP(NOW()-INTERVAL $PERIOD_FULL_NAME)
LIMIT 1;"

} done

