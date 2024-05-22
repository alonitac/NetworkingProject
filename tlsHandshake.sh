#!/bin/bash

if ! [ -e ~/cert-ca-aws.pem ]; then
     wget -P ~/ https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem
fi

clientHello=$(curl -X POST \
    -H "Content-Type: application/json" \
    -d '{
        "version": "1.3",
        "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"],
        "message": "Client Hello"
    }' \
    http://$1:8080/clienthello | jq '.')

sessionID=$(echo "$clientHello" | jq -r '.sessionID')
serverCert=$(echo "$clientHello" | jq -r '.serverCert')

echo "$serverCert" > ~/cert.pem

echo "Verifying Server Certificate..."
if ! openssl verify -CAfile ~/cert-ca-aws.pem ~/cert.pem ; then
    echo "Server Certificate is invalid."
    exit 5
fi
echo "cert.pem: OK"

touch ~/mainKeyTLS
openssl rand -base64 32 > ~/mainKeyTLS
master=$(cat ~/mainKeyTLS)
MASTER_KEY=$(openssl smime -encrypt -aes-256-cbc -in ~/mainKeyTLS -outform DER ~/cert.pem | base64 -w 0 )

goodCase=$(curl -s -X POST \
-H "Content-Type: application/json" \
-d '{
          "sessionID": "'"$sessionID"'",
          "masterKey": "'"$MASTER_KEY"'",
          "sampleMessage": "Hi server, please encrypt me and send to client!"
         }' \
         "http://$1:8080/keyexchange")

encryptedSampleMessage=$(echo "$goodCase" | jq -r '.encryptedSampleMessage')

sampleMessageCheck=$(echo "$encryptedSampleMessage" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$master" 2>/dev/null)

sampleMessage="Hi server, please encrypt me and send to client!"

if [ -z "$sampleMessageCheck" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi

if [ "$sampleMessageCheck" != "$sampleMessage" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi

echo "Client-Server TLS handshake has been completed successfully."
