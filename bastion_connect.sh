#!/bin/bash

##if [ $# -ne 2 ]; then
    ##echo "Usage: $0 <public_ip> <private_ip>"
   ## exit 5
##fi


if [ $# -eq 1 ]; then
   ssh -i $KEY_PATH ubuntu@$1
   exit 5
fi


if [ $# -eq 3 ]; then 
   ssh -i $KEY_PATH -N -L 2222:$2:22 ubuntu@"$1" &
   sleep 5
   ssh -i $KEY_PATH -p 2222 ubuntu@localhost $3
   exit 5
fi


if [ $# -eq 2 ]; then 
   ssh -i $KEY_PATH -N -L 2222:$2:22 ubuntu@"$1" &
   sleep 5
   ssh -i $KEY_PATH -p 2222 ubuntu@localhost 
   exit 5
fi


if [ -z $KEY_PATH ]; then
   echo "KEY_PATH env var is expected"
   exit 5
fi


if [ $# -ne 1 ]; then
    echo "Usage: $0 <public_ip> <private_ip>"
    exit 5
fi


##public_ip=$1
##private_ip=$2
##ssh -i $KEY_PATH -N -L 2222:$2:22 ubuntu@$1 &
##sleep 5
##ssh -i $KEY_PATH -p 2222 ubuntu@localhost