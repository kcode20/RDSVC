#!/bin/bash

# Input Variables
MYSQL_HOST=$1
MYSQL_PORT=$2
MYSQL_USER=$3
MYSQL_PASS=$4
MYSQL_DB=$5
S3_BUCKET=$6

# Move into /tmp
cd /tmp

# make sure mysqldump is accessible in /tmp
cp ./mysqldump /tmp/mysqldump
chmod 755 /tmp/mysqldump

# Define file for mysqldump output
file=$(date +%F).sql

# Call mysqldump and save it in defined file
mysqldump \
  --host ${MYSQL_HOST} \
  --port ${MYSQL_PORT} \
  -u ${MYSQL_USER} \
  --password="${MYSQL_PASS}" \
  ${MYSQL_DB} > ${file}

# Zip the mysql file and upload it to S3 delete the file locally
if [ "${?}" -eq 0 ]; then
  gzip ${file}
  aws s3 cp ${file}.gz s3://${S3_BUCKET}
  rm ${file}.gz
else
  echo "Error backing up mysql"
  exit 255
fi
