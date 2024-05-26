
#!/bin/bash

SAMPLE_MESSAGE="Hi server, please encrypt me and send to client!"

if [ ! -e ~/cert-ca-aws.pem ]; then
  wget -P ~/ https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem
fi

CLIENT_HELLO=$(curl -v -X POST  \  -H "Content-Type: application/json" \
  -d '{ "version": "1.3",
        "ciphersSuites": [ "TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256" ], 
        "message": "Client Hello" }' \
        http://$1:8080/clienthello | jq -r '.' )

if [ $? -ne 0 ]; then
  echo "Failed to send Client Hello."
  exit 1
fi

SESSION_ID=$(echo $CLIENT_HELLO | jq -r '.sessionID')
SERVER_CERT=$(echo $CLIENT_HELLO | jq -r '.serverCert')

echo "$SERVER_CERT" > ~/cert.pem
openssl verify -CAfile ~/cert-ca-aws.pem ~/cert.pem
if [ $? -ne 0 ]; then
  echo "Server Certificate is invalid."
  exit 5
fi
echo "SESSION_ID: $SESSION_ID"
echo "SERVER_CERT: $SERVER_CERT"
MASTER_KEY=$(openssl rand -base64 32) 
echo "$MASTER_KEY" > ~/temp
echo "MASTER_KEY: $MASTER_KEY"

if [ $? -ne 0 ]; then
  echo "Failed Master Key."
  exit 1
fi

MASTER_KEY_FINAL=$(openssl smime -encrypt -aes-256-cbc -in ~/temp -outform DER ~/cert.pem | base64 -w 0)
echo "MASTER_KEY_FINAL: $MASTER_KEY_FINAL"
echo "JSON Payload:"
echo "{ \"sessionID\": \"$SESSION_ID\",
        \"masterKey\": \"$MASTER_KEY_FINAL\",
        \"sampleMessage\": \"$SAMPLE_MESSAGE\" }" | jq .


KEY_EXCHANGE=$(curl -v -X POST  \  -H "Content-Type: application/json" \
  -d '{ "sessionID": "$SESSION_ID",
        "masterKey": "$MASTER_KEY_FINAL",
        "sampleMessage": "$SAMPLE_MESSAGE"}' \
        http://$1:8080/keyexchange)

if [ $? -ne 0 ]; then
  echo "Failed to do key exchange."
  exit 1
fi

SESSION_ID=$(echo $KEY_EXCHANGE | jq -r '.sessionID')
ENCRYPTED_SAMPLE_MESSAGE=$(echo $KEY_EXCHANGE | jq -r '.encryptedSampleMessage')

if [ $? -ne 0 ]; then
  echo "Falied to do encrypting"
  exit 1
fi

DECODED_ENCRYPTED_SAMPLE_MESSAGE=$(echo $ENCRYPTED_SAMPLE_MESSAGE | base64 -d |openssl enc -e -aes-256-cbc -pbkdf2 -k ~/temp)

if [ $? -ne 0 ]; then
  echo "Falied to do decode"
  exit 1
fi

if [ "$DECODED_ENCRYPTED_SAMPLE_MESSAGE" == "$SAMPLE_MESSAGE" ]; then
  echo "Client & Server TLS handshake has been completed successfully"
else
  echo "Server symmetric encryption using the exchanged master-key has failed"
  exit 6
fi

exit 0