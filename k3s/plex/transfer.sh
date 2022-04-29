#!/bin/bash
# /bin/sh transfer.sh %D %N bansion_ip  /media/bansion/plex/staging 
if [ "$#" -ne 4 ]
then
  echo "Incorrect usage $1,$2,$3,$4" >> ~/transfer_error.txt
  exit 1  
fi


source=$1$2
server=$3
destination=$4

echo "scp -r -i ~/.ssh/pi $source bansion@${server}:$4" >> ~/transfer.txt

scp -r -i ~/.ssh/pi "$source" bansion@${server}:$4
