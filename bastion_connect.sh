#!/bin/bash
if [ $# -eq 0 ]; then
    echo "Please provide bastion IP address"
fi
if [[ -z "${KEY_PATH}" ]]; then
    echo "KEY_PATH env var is expected"
    exit 5
fi

if [ $# -eq 2 ]; then
    echo "case 1"
    ssh -i $KEY_PATH ubuntu@$1 "ssh -i /home/ubuntu/private.pem ec2-user@$2"
elif [ $# -eq 1 ]; then
    echo "case 2"
    ssh -i $KEY_PATH ubuntu@$1
elif [ $# -eq 3 ]; then
    echo "case 3"
    ssh -i $KEY_PATH ubuntu@$1 "ssh -i /home/ubuntu/private.pem ec2-user@$2 $3"
fi

