#!/bin/sh

if [ $# -ne 1 ] ; then
    echo "Usage: $0 caconfname"
    exit 1
fi

openssl=openssl
caconf=$1.cnf

DAYS="-days 365"	# 1 year
CADAYS="-days 1095"	# 3 years

REQ="$openssl req -config $caconf"
CA="$openssl ca -config $caconf"
X509="$openssl x509"

CATOP="./$1"
CAKEY="$1key.pem"
CAREQ="$1req.pem"
CACERT="$1cert.pem"

DIRMODE=0700;

startdate=000101000000Z # 2000/01/01 00:00:00 z0
enddate=150101000000Z # 2015/01/01 00:00:00 z0

if [ -d $CATOP ] ; then
    echo "Error: $CATOP already exists! Delete or move it to make a new CA."
    exit 1
fi

echo "Creating CA directory hierarchy..."
mkdir -m $DIRMODE $CATOP
mkdir -m $DIRMODE $CATOP/certs
mkdir -m $DIRMODE $CATOP/crl
mkdir -m $DIRMODE $CATOP/newcerts
mkdir -m $DIRMODE $CATOP/private
touch ${CATOP}/index.txt
echo "unique_subject = no" > "$CATOP/index.txt.attr" # Needed to have multiple certs with same subject matter
echo "01" > ${CATOP}/crlnumber


echo "Making CA certificate ..."
$REQ -new -keyout ${CATOP}/private/$CAKEY -out ${CATOP}/$CAREQ -batch

$CA -create_serial -batch -selfsign -extensions v3_ca \
    -out ${CATOP}/$CACERT -keyfile ${CATOP}/private/$CAKEY \
    -passin pass:demo \
    -startdate $startdate -enddate $enddate \
    -infiles ${CATOP}/$CAREQ
    # $CADAYS

echo "Also making a DER version of the cert"
$X509 -in $CATOP/$CACERT -inform PEM -out $CATOP/${CACERT%.pem}.der -outform DER

echo "Copying CA certificate to ssl dir"
cp ${CATOP}/$CACERT $CACERT
