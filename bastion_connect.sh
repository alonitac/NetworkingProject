#!/bin/bash

#  44.200.79.40 $1
#10.0.1.166 $2

export KEY_PATH=/home/amir/Desktop/myKEY1.pem

if [ $# -eq 1 ]; then
   ssh -i $KEY_PATH ubuntu@$1
fi


if [ $# -eq 2 ]; then

  ssh -t -i $KEY_PATH ubuntu@$1 "ssh -i /home/ubuntu/key -t ubuntu@$2"
  
fi


if [ $# -eq 3 ]; then

   ssh -t -i $KEY_PATH ubuntu@$1 "ssh -i /home/ubuntu/key -t ubuntu@$2 $3"

fi

if [ -z $1 ]; then
   echo "Please provide bastion IP address"
   exit 5
fi

if [ -z $KEY_PATH ]; then
  echo "KEY_PATH env var is expected"
  exit 5
fi
