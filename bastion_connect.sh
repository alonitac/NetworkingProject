#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Please provide bastion IP address"
fi
if [[ -z "${KEY_PATH}" ]]; then
    echo "KEY_PATH env var is expected"
    exit 5
fi

if [ $# -eq 2 ]; then
    ssh -i $KEY_PATH ubuntu@$1 "ssh -i /home/ubuntu/private.pem ubuntu@$2"
elif [ $# -eq 1 ]; then
    ssh -i $KEY_PATH ubuntu@$1
elif [ $# -eq 3 ]; then
    ssh -i $KEY_PATH ubuntu@$1 "ssh -i /home/ubuntu/private.pem ubuntu@$2 $3"
fi
