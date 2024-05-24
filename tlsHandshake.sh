#!/bin/bash

# Check if an IP address is provided as an argument
if [ $# -ne 1 ]; then
    echo "You need to provide the IP address as an argument."
    exit 5
fi

# Send a request to the server and store the response in the "response" variable
response=$(curl -X POST "$1:8080/clienthello" -H "Content-Type: application/json" -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}')

# Store the session ID and server certificate in the "sessionID" and "cert.pem" files, respectively
sessionID=$(echo "$response" | jq -r '.sessionID')
echo "$response" | jq -r '.serverCert' > cert.pem

# Download the CA certificate for verification
wget https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem

# Verify the server certificate
output=$(openssl verify -CAfile cert-ca-aws.pem cert.pem)

# Check if the certificate verification succeeded
if [ "$output" != "cert.pem: OK" ]; then
    echo "Server Certificate is invalid."
    exit 5
fi

# Generate a master key and save it to the "master_key" file
openssl rand -base64 32 > master_key

# Encrypt the master key and save it to the "encrypted_key" variable
encrypted_key=$(openssl smime -encrypt -aes-256-cbc -in master_key -outform DER cert.pem | base64 -w 0)

# Send the encrypted key to the server and store the response in the "response2" variable
response2=$(curl -X POST "$1:8080/keyexchange" -H "Content-Type: application/json" -d '{"sessionID": "'"${sessionID}"'", "masterKey": "'"${encrypted_key}"'", "sampleMessage": "Hi server, please encrypt me and send to client!"}')

# Extract the encrypted sample message from the server response
sample_message=$(echo "$response2" | jq -r '.encryptedSampleMessage')

# Decrypt the sample message
decrypted_message=$(echo "$sample_message" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$(cat master_key)")

# Check if the decrypted message matches the original message
if [ "$decrypted_message" == "Hi server, please encrypt me and send to client!" ]; then
    echo "Client-Server TLS handshake has been completed successfully"
else
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi