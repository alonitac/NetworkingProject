#/bin/bash

if [ $# -eq 1 ]; then
	rm -rf temp/
	mkdir temp

	if [ "$(curl $1:8080/status)" = "Hi! I'm available, let's start the TLS handshake" ]; then
		request=$(curl -v -H "Content-Type: application/json" -d '{"version": "1.3", "ciphersSuites": ["TLS_AES_128_GCM_SHA256", "TLS_CHACHA20_POLY1305_SHA256"], "message": "Client Hello"}' $1:8080/clienthello) > /dev/null
		sessionID=$(echo $request | jq -r .sessionID) > /dev/null
		echo $request | jq -r .serverCert > temp/cert.pem

		if ! [ -e ./temp/cert-ca-aws.pem ]; then
			wget -P temp/ https://alonitac.github.io/DevOpsTheHardWay/networking_project/cert-ca-aws.pem > /dev/null
		fi

		openssl verify -CAfile temp/cert-ca-aws.pem temp/cert.pem > /dev/null
		sample_massage="Hi server, please encrypt me and send to client!"
		if [ $? -eq 0 ]; then
			openssl rand -base64 32 > temp/key_enc
			openssl smime -encrypt -aes-256-cbc -in temp/key_enc -outform DER temp/cert.pem | base64 -w 0 > temp/encrypt
			msg=$(curl -v -H "Content-Type: application/json" -d '{"sessionID": "'"$sessionID"'", "masterKey": "'"$(cat temp/encrypt)"'", "sampleMessage": "'"$sample_massage"'"}' $1:8080/keyexchange | jq -r .encryptedSampleMessage) > /dev/null
			output=$(echo "$msg" | base64 -d | openssl enc -d -aes-256-cbc -pbkdf2 -k $(cat temp/key_enc)) > /dev/null
		else
			echo "Server Certificate is invalid."
			exit 5
		fi

		if [ "${output}" = "${sample_massage}" ]; then
			echo "Client-Server TLS handshake has been completed successfully"
		else
			echo "Server symmetric encryption using the exchanged master-key has failed."
			exit 6
		fi
	else
		echo "Server not responding"
		exit 5
	fi
else
	exit 5
fi

rm -rf temp/
