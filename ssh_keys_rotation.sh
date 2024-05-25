#!/bin/bash

echo "Creating old key copy"
cp key old_key
cp key.pub old_key.pub
sleep 1
chmod 600 old_key
sleep 1

echo "removing regular key"
rm ~/key
rm ~/key.pub

sleep 2

echo "generating new key"
ssh-keygen -f ~/key -N ""
sleep 5

scp -i ~/old_key -p key.pub ubuntu@$1:
ssh -i ~/old_key ubuntu@$1 cp ~/key.pub .ssh/authorized_keys








