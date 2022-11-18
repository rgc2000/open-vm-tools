#!/bin/sh
##
##  new-cert.sh - create a self signed certificate 
##  for driver signature
##

# Create the key only if not already done
if [ ! -f open-vm-tools.key ]; then
    openssl genrsa -out open-vm-tools.key 2048
fi

# Self-sign the certificate
CONFIG="root-ca.conf"
cat >$CONFIG <<EOT
[ req ]
default_bits			= 2048
default_keyfile			= ca.key
distinguished_name		= req_distinguished_name
x509_extensions			= v3_ca
string_mask			= nombstr
req_extensions			= v3_req
[ req_distinguished_name ]
[ v3_ca ]
keyUsage                        = digitalSignature, keyCertSign
basicConstraints		= critical,CA:true
subjectKeyIdentifier		= hash
extendedKeyUsage                = codeSigning
[ v3_req ]
nsCertType			= objsign
EOT

openssl req -new -x509 -days 4033 -subj "/O=Community/OU=OpenVMTools/CN=elfsign@solaris11" -config $CONFIG -key open-vm-tools.key -out open-vm-tools.crt

rm -f $CONFIG
