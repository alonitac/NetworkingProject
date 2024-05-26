#!/bin/bash

if [ -z $1 ]; then
   echo "Please provide bastion IP address"
   exit 5
fi

if [ -z $KEY_PATH ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi

if [ -z $2 ]; then
  ssh -i $KEY_PATH ubuntu@$1 -t

fi


if [ -z "$3" ]; then
   ssh -i $KEY_PATH ubuntu@$1 -t "ssh -i /home/ubuntu/key -t ubuntu@$2"
else
   ssh -i $KEY_PATH ubuntu@$1 -t "ssh -i /home/ubuntu/key -t ubuntu@$2" "$3"
fi


