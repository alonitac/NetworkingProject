#!/bin/bash

TheHello=$(curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
         "version": "1.3",
         "ciphersSuites": ["TLS_AES_128_GCM_SHA256",
         "TLS_CHACHA20_POLY1305_SHA256"],
         "message": "Client Hello"
      }' \
    http://$1:8080/clienthello | jq '.' )

sessionID=$(echo "$TheHello" | jq -r '.sessionID')
serverCert=$(echo "$TheHello" | jq -r '.serverCert')

echo "$serverCert" > ~/cert.pem
echo "$sessionID"> ~/NEWPR.pem


value=$(openssl verify -CAfile ~/cert-ca-aws.pem ~/cert.pem )
if [ "$value" ];then
      echo "cert.pem: OK"
else
      echo "Server Certificate is invalid."
      exit 5
fi

touch ~/main-key
openssl rand -base64 32 > ~/main-key
master=$(cat ~/main-key)
MASTER_KEY=$(openssl smime -encrypt -aes-256-cbc -in ~/main-key -outform DER ~/cert.pem | base64 -w 0 )

PrintNew=$(curl -s -X POST \
-H "Content-Type: application/json" \
-d '{
          "sessionID": "'"$sessionID"'",
          "masterKey": "'"$MASTER_KEY"'",
          "sampleMessage": "Hi server, please encrypt me and send to client!"
         }' \
         "http://$1:8080/keyexchange")

encryptedSampleMessage=$(echo "$PrintNew" | jq -r '.encryptedSampleMessage')

the_sample_message_check=$(echo "$encryptedSampleMessage" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k "$master")
samplemessage="Hi server, please encrypt me and send to client!"

if [ "$the_sample_message_check" != "$samplemessage" ]; then
    echo "Server symmetric encryption using the exchanged master-key has failed."
    exit 6
fi
echo "Client-Server TLS handshake has been completed successfully."