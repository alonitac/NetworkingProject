#!/bin/bash

URL="http://$1:8080"

MESSAGE_KEY_EXCHANGE="Hi server, please encrypt me and send to client!"


send_hello() {
    echo "Sending client hello..."
    hello_output=$(curl -s -X POST -H "Content-Type: application/json" -d '{
    "version": "1.3",
    "ciphersSuites": [
        "TLS_AES_128_GCM_SHA256",
        "TLS_CHACHA20_POLY1305_SHA256"
    ], 
    "message": "Client Hello" 
    }' $URL/clienthello)
    if [ $? -ne 0 ]; then
        echo "Sending hello failed!"
        exit 1
    fi
}

keyexchange() {
    echo "Sending key exchange..."
    key_exchange_output=$(curl -s -X POST -H "Content-Type: application/json" -d "{
        \"sessionID\": \"$session_id\",
        \"masterKey\": \"$master_cert\",
        \"sampleMessage\": \"$MESSAGE_KEY_EXCHANGE\"
    }" $URL/keyexchange)
    if [ $? -ne 0 ]; then
        echo "Sending key exchange failed!"
        exit 1
    fi
}

send_hello

session_id=$(echo "$hello_output" | jq -r '.sessionID')
server_cert=$(echo "$hello_output" | jq -r '.serverCert')

echo "$server_cert" > server_cert.pem

echo "Session ID is: $session_id"

echo "Validating server certficiate with CA..."
openssl verify -CAfile cert-ca-aws.pem server_cert.pem
if [ $? -ne 0 ]; then
    echo "Server Certificate is invalid."
    exit 5
fi

echo "Generating master key..."
master_key=$(openssl rand -base64 32)
echo "$master_key" > master_key.txt

master_cert=$(openssl smime -encrypt -aes-256-cbc -in master_key.txt -outform DER server_cert.pem | base64 -w 0)
if [ $? -ne 0 ]; then
    echo "Creating master certificate failed!"
    exit 1
fi

keyexchange

base64_sample_message=$(echo "$key_exchange_output" | jq -r '.encryptedSampleMessage')

result_from_server=$(echo "$base64_sample_message" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k $master_key)
if [ $? -ne 0 ]; then
    echo "Decrypting result from server failed!"
    exit 1
fi

if [ "$MESSAGE_KEY_EXCHANGE" == "$result_from_server" ]; then
    echo "Client-Server TLS handshake has been completed successfully"
else
    echo "Server symmetric encryption using the exchanged master-key has failed"
    exit 6
fi