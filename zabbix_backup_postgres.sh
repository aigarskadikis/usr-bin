#!/bin/bash

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
PGPORT=7413 PGPASSWORD=postgres PGUSER=postgres psql -h 158.101.218.248 -t -A -c "SELECT datname FROM pg_database where datname not in ('template0','template1','postgres','dummy_db')"
) ; do echo $db; PGPORT=7413 PGPASSWORD=postgres PGUSER=postgres pg_dump -h 158.101.218.248 $db | xz > $dest/$db.sql.xz ; done

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

