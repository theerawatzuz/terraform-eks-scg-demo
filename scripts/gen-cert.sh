#!/bin/bash
# Generate self-signed wildcard TLS certificate for *.thebrainsurf.site
# Usage: ./scripts/gen-cert.sh [namespace]
# Default namespace: default

set -e

DOMAIN="thebrainsurf.site"
NAMESPACE="${1:-default}"
SECRET_NAME="wildcard-tls"
CERT_DIR="./certs"
DAYS=3650  # 10 years

mkdir -p "$CERT_DIR"

echo "Generating self-signed wildcard certificate for *.$DOMAIN ..."

# Generate CA key and certificate
openssl genrsa -out "$CERT_DIR/ca.key" 4096

openssl req -new -x509 -days "$DAYS" -key "$CERT_DIR/ca.key" \
  -out "$CERT_DIR/ca.crt" \
  -subj "/CN=thebrainsurf-ca/O=thebrainsurf/C=TH"

# Generate server key
openssl genrsa -out "$CERT_DIR/tls.key" 2048

# Generate CSR with SAN for wildcard
openssl req -new -key "$CERT_DIR/tls.key" \
  -out "$CERT_DIR/tls.csr" \
  -subj "/CN=*.$DOMAIN/O=thebrainsurf/C=TH"

# Create SAN extension config
cat > "$CERT_DIR/san.ext" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.$DOMAIN
DNS.2 = $DOMAIN
EOF

# Sign the certificate with CA
openssl x509 -req -days "$DAYS" \
  -in "$CERT_DIR/tls.csr" \
  -CA "$CERT_DIR/ca.crt" \
  -CAkey "$CERT_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERT_DIR/tls.crt" \
  -extfile "$CERT_DIR/san.ext" \
  -extensions v3_req

echo ""
echo "Certificate generated:"
echo "  $CERT_DIR/tls.crt"
echo "  $CERT_DIR/tls.key"
echo ""
echo "Certificate details:"
openssl x509 -in "$CERT_DIR/tls.crt" -noout -subject -issuer -dates -ext subjectAltName

# Generate Kubernetes TLS secret manifest
cat > tls-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $NAMESPACE
type: kubernetes.io/tls
data:
  tls.crt: $(base64 -i "$CERT_DIR/tls.crt" | tr -d '\n')
  tls.key: $(base64 -i "$CERT_DIR/tls.key" | tr -d '\n')
EOF

echo ""
echo "Kubernetes secret manifest created: tls-secret.yaml"
echo ""
echo "Apply with:"
echo "  kubectl apply -f tls-secret.yaml"
echo ""
echo "To renew, simply re-run this script."
