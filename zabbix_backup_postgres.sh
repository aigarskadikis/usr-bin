#!/bin/bash

DBHOST=158.101.218.248
DBPORT=7413

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
clock=$(date +%H%M)
volume=/backup/postgres
dest=$volume/$year/$month/$day/$clock

if [ ! -d "$dest" ]; then
  mkdir -p "$dest"
fi

for db in $(
PGPORT=$DBPORT PGPASSWORD=zabbix PGUSER=postgres psql -h $DBHOST -t -A -c "SELECT datname FROM pg_database where datname not in ('template0','template1','postgres','dummy_db')"
) ; do
echo $db

# backup database without hypertables
# use contom format (which is compressed by default
PGHOST=$DBHOST \
PGPORT=$DBPORT \
PGUSER=postgres \
PGPASSWORD=zabbix \
pg_dump \
--dbname=$db \
--format=c \
--blobs \
--exclude-table-data '*.history*' \
--exclude-table-data '*.trends*' \
--exclude-table-data='_timescaledb_internal._hyper*' \
--file=$dest/$db.pg_dump.custom

# backup raw data individually
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
PGHOST=$DBHOST \
PGPORT=$DBPORT \
PGUSER=postgres \
PGPASSWORD=zabbix \
psql --dbname=$db \
-c "COPY (SELECT * FROM $TABLE) TO stdout DELIMITER ',' CSV" | \
xz > $dest/$db.old_$TABLE.csv.xz
} done
# end of table by table

# end per database
done

# remove older files than 30 days
echo -e "\nThese files will be deleted:"
find /backup/postgres -type f -mtime +15
# delete files
find /backup/postgres -type f -mtime +15 -delete

echo -e "\nRemoving empty directories:"
find /backup/postgres -type d -empty -print
# delete empty directories
find /backup/postgres -type d -empty -print -delete

rclone -vv sync $volume BackupPostgreSQL:postgres

