#!/bin/bash

##if [ $# -ne 2 ]; then
    ##echo "Usage: $0 <public_ip> <private_ip>"
   ## exit 5
##fi
if [ ! -n "$KEY_PATH" ]; then
   echo "KEY_PATH env var is expected"
   exit 5
fi


if [ $# -lt 1 ]; then
    echo "Please provide bastion IP address"
    exit 5
fi

if [ $# -eq 1 ]; then
   ssh -t -i $KEY_PATH ubuntu@$1
   exit 5
fi

if [ $# -eq 3 ]; then 
   ssh -t -i $KEY_PATH ubuntu@$1 "ssh -t -i ~/key ubuntu@$2 $3"
   exit 5
fi


if [ $# -eq 2 ]; then 
   ssh -t -i $KEY_PATH  ubuntu@$1 "ssh -t -i ~/key ubuntu@$2"
   exit 5
fi




##public_ip=$1
##private_ip=$2
##ssh -i $KEY_PATH  ubuntu@$1 ssh -i $KEY_PATH  ubuntu@$2

##ssh -i $KEY_PATH  ubuntu@$2