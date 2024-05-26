#!/bin/bash


cp newkey oldkey
cp newkey.pub oldkey.pub
chmod 600 oldkey
rm ~/newkey
rm ~/newkey.pub

ssh-keygen -t rsa -b 4096 -f newkey -N ""

scp -i oldkey -p newkey.pub ubuntu@$1:
ssh -i oldkey ubuntu@$1 cp ~/newkey.pub .ssh/authorized_keys