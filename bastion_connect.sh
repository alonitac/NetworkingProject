#!/bin/bash
if [ -z "$KEY_PATH" ]; then
echo "KEY_PATH env var is expected"
exit 5
fi

num_of_arguments=$#
if [ $num_of_arguments -eq 0 ]; then
   echo "Please provide bastion IP address"
   echo "You can enter 3 arguments in the following order [bastion ip] [private ip] [command]"
   exit 5
fi

if [ $num_of_arguments -eq 1 ]; then
   bastion_ip=$1
   ssh -i "$KEY_PATH" ubuntu@$1
fi

if [ $num_of_arguments -eq 2 ]; then
   bastion_ip=$1
   private_ip=$2
   ssh -i "$KEY_PATH" -t ubuntu@$1 "ssh -i Projectinstans2-kp.pem -t ubuntu@$2"
fi

if [ $num_of_arguments -eq 3 ]; then
   bastion_ip=$1
   private_ip=$2
   command=$3
   ssh -i "$KEY_PATH" -t ubuntu@$1 "ssh -i Projectinstans2-kp.pem -t ubuntu@$2 '$command'"
fi
