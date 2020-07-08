#!/bin/bash
# (auth is in ~/.my.cnf)

# size before pruning
df /var/lib/mysql

command="CALL partition_maintenance_all('zabbix');"

# perform partition maintenance to drop all rolloff data
mysql zabbix -e "$command"

# size after pruning
df /var/lib/mysql

