#!/bin/bash

if [ -z "$1" ]; then
    echo "Please provide bastion IP address"
    exit 5
fi

cp key old_key
cp key.pub old_key.pub
chmod 600 old_key
rm ~/key
rm ~/key.pub
ssh-keygen -f ~/key -N "" ##no password
sleep 5
scp -i old_key -p key.pub ubuntu@$1:
ssh -i old_key ubuntu@$1 cp ~/key.pub .ssh/authorized_keys








