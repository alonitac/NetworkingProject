#!/bin/bash

CLIENT_HELLO=$(curl -X POST "$1:8080/clienthello" -H "Content-Type: application/json" -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}')

SESSION_ID=$(echo "$CLIENT_HELLO" | jq -r '.sessionID')
SERVER_CERT=$(echo $CLIENT_HELLO | jq -r '.serverCert')

echo "$SERVER_CERT" > ~/cert.pem

if [ ! -e ~/cert-ca-aws.pem ]; then
  wget -P ~/ https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem
fi

openssl verify -CAfile ~/cert-ca-aws.pem ~/cert.pem
if [ $? -ne 0 ]; then
  echo "Server Certificate is invalid."
  exit 5
fi

openssl rand -base64 32 > master_key

MASTER_KEY_ENCRTPTED=$(openssl smime -encrypt -aes-256-cbc -in master_key -outform DER cert.pem | base64 -w 0)

KEY_EXCHANGE=$(curl -X POST "$1:8080/keyexchange" -H "Content-Type: application/json" -d '{"sessionID": "'"${SESSION_ID}"'", "masterKey": "'"${MASTER_KEY_ENCRTPTED}"'", "sampleMessage": "Hi server, please encrypt me and send to client!"}')

ENCRYPTED_SAMPLE_MESSAGE=$(echo "$KEY_EXCHANGE" | jq -r '.encryptedSampleMessage')

DECRYPTED_SAMPLE_MESSAGE=$(echo "$ENCRYPTED_SAMPLE_MESSAGE" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$(cat master_key)")

if [ "$DECRYPTED_SAMPLE_MESSAGE" == "Hi server, please encrypt me and send to client!" ]; then
    echo "Client-Server TLS handshake has been completed successfully"
else
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi
