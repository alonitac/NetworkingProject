#!/bin/bash

if [ $(echo $KEY_PATH | grep .pem)$? = 1 ]; then
	echo "Error: KEY_PATH env var is expected"
	exit 5
elif [ $# -eq 1 ]; then
	ssh -i $KEY_PATH -t ubuntu@$1
elif [ $# -eq  2 ]; then
	ssh -i $KEY_PATH -t ubuntu@$1 "ssh -i ~/ssh_new_key/new_key.pem -t ubuntu@$2"
elif [ $# -eq 3 ]; then
	ssh -i $KEY_PATH -t ubuntu@$1 "ssh -i ~/ssh_new_key/new_key.pem -t ubuntu@$2 '$3'"
else
	exit 5
fi
