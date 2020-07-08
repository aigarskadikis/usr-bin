#!/bin/bash

# this script woks without password inline because the global 'env' contains
# PGUSER=postgres
# PGPASSWORD=zabbix
 
versions="2.4
3.0
3.2
3.4
4.0
4.2
4.4
5.0"
 
if [ ! -d "~/zabbix-source" ]; then
git clone https://git.zabbix.com/scm/zbx/zabbix.git ~/zabbix-source
fi
 
cd ~/zabbix-source
 
echo "$versions" | while IFS= read -r ver
do {
echo $ver
 
db=z`echo $ver | sed "s|\.||"`
echo $db
git reset --hard HEAD && git clean -fd
git checkout release/$ver
./bootstrap.sh && ./configure && make dbschema
 
env | grep PGPASSWORD

if [ $? -eq 0 ]; then
dropdb -p 7411 $db

createdb -p $1 -O zabbix $db 
 
# insert schema and data
cat database/postgresql/schema.sql database/postgresql/images.sql database/postgresql/data.sql | psql -p $1 --user=zabbix $db

else
echo please install global 'env' variables:
echo PGUSER=postgres
echo PGPASSWORD=zabbix

fi
 
} done

