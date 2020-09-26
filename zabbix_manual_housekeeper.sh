#!/bin/bash

date

SLEEP=1
DB=zabbix

mysql $DB --raw --batch -N -e "SELECT DISTINCT items.history
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status IN (0,1)
AND items.value_type=0
AND items.history LIKE '%d';
"

