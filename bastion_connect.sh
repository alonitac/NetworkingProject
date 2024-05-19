#!/bin/bash

if [ -z "$KEY_PATH" ]
then
echo "KEY_PATH env var is expected"
exit 5
fi

if [ -z "$1" ]
then
echo "Please provide bastion IP address"
exit 5
fi

if [ -z "$2" ]
then
ssh -i $KEY_PATH  -t ubuntu@$1
fi

if [ -z "$3" ]
then
ssh -i $KEY_PATH  -t ubuntu@$1 "ssh -i ~/newkey -t ubuntu@$2"
fi
ssh -i $KEY_PATH  -t ubuntu@$1 "ssh -i ~/newkey  -t ubuntu@$2" "$3" 
