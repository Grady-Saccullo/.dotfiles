#!/bin/bash -e

# Adds a self-signed code-signing certificate named <identity> to the login keychain, unless an
# identity with that name is already there (./README.md).
if [[ $# != 1 ]]; then
	echo "usage: create-identity <identity>" >&2
	exit 2
fi
identity=$1

if security find-identity -p codesigning | grep -qF "\"$identity\""; then
	echo "codesign: \"$identity\" is already in the keychain"
	exit 0
fi

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
cat >"$dir/req.cnf" <<EOF
[req]
distinguished_name = dn
prompt = no
x509_extensions = ext
[dn]
CN = $identity
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF
openssl req -x509 -newkey rsa:2048 -nodes -days 7300 -config "$dir/req.cnf" -keyout "$dir/key.pem" -out "$dir/cert.pem"
# The password only protects the file on its way into the keychain.
openssl pkcs12 -export -inkey "$dir/key.pem" -in "$dir/cert.pem" -out "$dir/identity.p12" -passout pass:import
security import "$dir/identity.p12" -k "$HOME/Library/Keychains/login.keychain-db" -P import -T /usr/bin/codesign
echo "codesign: added \"$identity\" to the login keychain"
