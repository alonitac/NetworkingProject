#!/bin/bash

##if [ $# -ne 2 ]; then
    ##echo "Usage: $0 <public_ip> <private_ip>"
   ## exit 5
##fi

key=~/key

if [ ! -n "$KEY_PATH" ]; then
   echo "KEY_PATH env var is expected"
   exit 5
fi


if [ -z "$1" ]; then
    echo "Please provide bastion IP address"
    exit 5
fi

if [ -z "$2" ]; then
   ssh  -i $KEY_PATH -t ubuntu@$1
fi

if [ -z "$3" ]; then
   ssh -i $KEY_PATH  -t ubuntu@$1 "ssh -i /home/ubuntu/key -t ubuntu@$2"
else
   ssh -i $KEY_PATH -t ubuntu@$1 "ssh -i /home/ubuntu/key -t ubuntu@$2 $3"
fi



##public_ip=$1
##private_ip=$2
##ssh -i $KEY_PATH  ubuntu@$1 ssh -i $KEY_PATH  ubuntu@$2

##ssh -i $KEY_PATH  ubuntu@$2