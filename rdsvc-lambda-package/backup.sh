#!/bin/sh

# Input Variables
MYSQL_HOST=$1
MYSQL_PORT=$2
MYSQL_USER=$3
MYSQL_PASS=$4
MYSQL_DB=$5
S3_BUCKET=$6

cp "./rdsvc-lambda-package/mysqldump" /tmp/mysqldump
chmod 755 /tmp/mysqldump

# Define file for mysqldump output
file=/tmp/$(date +%F).sql

# Call mysqldump and save it in defined file
/tmp/mysqldump \
  --host "${MYSQL_HOST}" \
  --port ${MYSQL_PORT} \
  -u ${MYSQL_USER} \
  --password="${MYSQL_PASS}" \
  ${MYSQL_DB} > ${file}

