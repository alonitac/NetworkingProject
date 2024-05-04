coo#!/bin/bash

echo -e "\n\n\n-----------------------------------------------------------------------------------------------------------------"
echo "Running Test Case I: Connect to the public instance using the SSH private key provided to the automated test in the PUBLIC_INSTANCE_SSH_KEY secret"
echo "Command: 'ssh -i ./private_key ubuntu@"$PUBLIC_IP"'"
echo -e "-----------------------------------------------------------------------------------------------------------------"


OUTPUT=$(ssh -i ./private_key ubuntu@$PUBLIC_IP 'echo $SSH_CONNECTION')
if [ $? -ne "0" ]
then
  echo "$OUTPUT"
  echo -e "\n\nCould not connect to the public instance using the provided SSH key. Please make sure the instance is running, you've launched Ubuntu instances, and the corresponding public key was added to the '~/.ssh/authorized_keys' file in your public instance."
  exit 1
fi

if ! [ -n "$OUTPUT" ]
then
  echo -e "\n\nSuccessfully connected to your public instance, but the SSH_CONNECTION environment variable, which required to extract the instance's private IP address, does not exist."
  echo "Found: $OUTPUT"
  exit 1
fi

PUBLIC_INSTANCE_PRIVATE_IP=$(echo $OUTPUT | awk '{print $3}')

if ! echo $PUBLIC_INSTANCE_PRIVATE_IP | grep -q -P "10\.0\.0\.[0-9]{1,3}"
then
  echo -e "\n\nSuccessfully connected to your public instance, but could not extract its private IP address from the SSH_CONNECTION environment variable, or the private address does not belong to the expected CIDR of the public subnet: 10.0.0.0/24.\n"
  echo "Found: $PUBLIC_INSTANCE_PRIVATE_IP"
  exit 1
fi

echo '✅ Test case I was completed successfully!'

echo -e "\n\n\n-----------------------------------------------------------------------------------------------------------------"
echo "Running Test Case II: Execute bastion_connect.sh without providing the KEY_PATH env var."
echo -e "-----------------------------------------------------------------------------------------------------------------"

bash bastion_connect.sh $PUBLIC_IP $PRIVATE_IP ls &> /dev/null

EXIT_CODE=$?

if [ "$EXIT_CODE" -ne "5" ]
then
  echo -e "\n\nExpected bastion_connect.sh to be exited with code 5\n"
  echo "But found: $EXIT_CODE"
  exit 1
fi

echo '✅ Test case II was completed successfully!'


echo -e "\n\n\n-----------------------------------------------------------------------------------------------------------------"
echo "Running Test Case III: Execute bastion_connect.sh without providing parameters"
echo -e "-----------------------------------------------------------------------------------------------------------------"

bash bastion_connect.sh &> /dev/null

EXIT_CODE=$?

if [ "$EXIT_CODE" -ne "5" ]
then
  echo -e "\n\nExpected bastion_connect.sh to be exited with code 5\n"
  echo "But found: $EXIT_CODE"
  exit 1
fi

echo '✅ Test case III was completed successfully!'


echo -e "\n\n\n-----------------------------------------------------------------------------------------------------------------"
echo "Running Test Case IV: Connect to the private instance through the public instance and execute the"
echo "                      'printenv' command (which prints the env vars exist in the private instance)."
echo "Command: bastion_connect.sh $PUBLIC_IP $PRIVATE_IP printenv"
echo -e "-----------------------------------------------------------------------------------------------------------------"

export KEY_PATH=$(pwd)/private_key
OUTPUT=$(bash bastion_connect.sh $PUBLIC_IP $PRIVATE_IP printenv)

if [ $? -ne "0" ]
then
  echo "$OUTPUT"
  echo -e "\n\nThere may be issues with the connection to the public instance, the connection to the private instance through the public instance, or the execution of the provided command (printenv) in the private instance."
  exit 1
fi

if ! echo $OUTPUT | grep -q -P "SSH_CONNECTION="
then
    echo -e "\n\nYour script was executed successfully, but the SSH_CONNECTION environment variable is missing.\n"
    echo "That might indicate that the SSH connection is invalid, or your bastion_connect.sh script has connected using methods other than the default ssh client."
    exit 1
fi

if ! echo $OUTPUT | grep -q -P "SSH_CONNECTION=$PUBLIC_INSTANCE_PRIVATE_IP .* $PRIVATE_IP"
then
  echo -e "\n\nYour script executed successfully, However, the SSH_CONNECTION environment variable is expected to follow this format: SSH_CONNECTION=$PUBLIC_INSTANCE_PRIVATE_IP [PORT] $PRIVATE_IP [PORT].\nInstead, it was found to be: $OUTPUT.\n"
  echo "This discrepancy may occur if the 'bastion_connect.sh' script has connected to instances not listed in the 'ec2_instances.json' file."
  exit 1
fi

echo '✅ Test case IV was completed successfully!'



echo -e "\n\n\n-----------------------------------------------------------------------------------------------------------------"
echo "Running Test Case V: Check that the private instance has no internet access."
echo "Command: bastion_connect.sh $PUBLIC_IP $PRIVATE_IP nc -z -w3 8.8.8.8 80"
echo -e "-----------------------------------------------------------------------------------------------------------------"

bash bastion_connect.sh $PUBLIC_IP $PRIVATE_IP "nc -z -w3 8.8.8.8 53"

if [ "$?" -eq "0" ]
then
  echo -e "\n\nThe private instance was able to communicate with the Internet, but was expected to not be able.\n"
  exit 1
fi

echo '✅ Test case V was completed successfully!'

