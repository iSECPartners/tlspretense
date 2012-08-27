#!/bin/sh

# Output in a more compatible format (Opera rejects PEM...)
echo "Creating a DER version of the cert:"
echo "==================================="
openssl x509 -in $1 -inform PEM -out ${1%.pem}.der -outform DER
