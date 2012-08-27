#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 name"
    exit 1
fi

base=$1
conf=$1.cnf

keyname=${base}key.pem
keynopassname=${base}key-nopass.pem
reqname=${base}req.pem
certname=${base}cert.pem

# create a new request
echo "Generating a new certificate request:"
echo "====================================="
openssl req -config $conf -new -keyout $keyname -out $reqname -days 30 -batch 2>&1
[ $? -eq 0 ] || exit 1

## have the CA sign it
#echo "Now the CA will sign it:"
#echo "========================"
#openssl ca -batch -config $conf -policy policy_anything -out $certname -passin pass:demo -infiles $reqname 2>&1
#[ $? -eq 0 ] || exit 1

echo "Self sign the certificate"
echo "========================="
openssl x509 -req -days 365 -extfile $conf -extensions v3_req -in $reqname -passin pass:demo -signkey $keyname -out $certname
[ $? -eq 0 ] || exit 1

openssl x509 -in $certname -noout -text

# strip the passphrase from the private key
echo "Now strip off the passphrase:"
echo "============================="
openssl rsa -in $keyname -passin pass:demo -out $keynopassname 2>&1
[ $? -eq 0 ] || exit 1

