#!/bin/bash
set -e

echo "=== Broker Service Token & Subject Info ==="
echo ""

# Configuration
KEYCLOAK_URL="http://localhost:8080"
BROKER_REALM="broker"
BROKER_CLIENT_ID="broker-service"
BROKER_CLIENT_SECRET="broker-secret-12345"

echo "Getting OIDC token for broker service..."
TOKEN_RESPONSE=$(curl -s -X POST \
  "${KEYCLOAK_URL}/realms/${BROKER_REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${BROKER_CLIENT_ID}" \
  -d "client_secret=${BROKER_CLIENT_SECRET}")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ "$ACCESS_TOKEN" = "null" ] || [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get broker access token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

echo "✅ Broker token retrieved successfully"
echo ""

# Decode JWT to extract subject and other claims
echo "=== Token Information ==="
echo "Full Access Token:"
echo "$ACCESS_TOKEN"
echo ""

# Decode JWT payload (base64 decode the middle part)
PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d. -f2)
# Add padding if needed for base64 decoding
PAYLOAD_PADDED=$(printf "%s" "$PAYLOAD" | sed 's/$/===/' | head -c $((${#PAYLOAD} + 3 - ${#PAYLOAD} % 4)))
DECODED_PAYLOAD=$(echo "$PAYLOAD_PADDED" | base64 -d 2>/dev/null | jq .)

echo "Decoded Token Payload:"
echo "$DECODED_PAYLOAD"
echo ""

# Extract specific claims
SUBJECT=$(echo "$DECODED_PAYLOAD" | jq -r '.sub // "N/A"')
ISSUER=$(echo "$DECODED_PAYLOAD" | jq -r '.iss // "N/A"')
CLIENT_ID_CLAIM=$(echo "$DECODED_PAYLOAD" | jq -r '.clientId // .client_id // "N/A"')
EXPIRY=$(echo "$DECODED_PAYLOAD" | jq -r '.exp // "N/A"')
ISSUED_AT=$(echo "$DECODED_PAYLOAD" | jq -r '.iat // "N/A"')
AUDIENCE=$(echo "$DECODED_PAYLOAD" | jq -r '.aud // "N/A"')
SCOPES=$(echo "$DECODED_PAYLOAD" | jq -r '.scope // "N/A"')

echo "=== Key Claims ==="
echo "Subject (sub): $SUBJECT"
echo "Issuer (iss): $ISSUER"
echo "Client ID: $CLIENT_ID_CLAIM"
echo "Audience (aud): $AUDIENCE"
echo "Scopes: $SCOPES"
echo "Expires at (exp): $EXPIRY"
echo "Issued at (iat): $ISSUED_AT"

if [ "$EXPIRY" != "N/A" ]; then
  EXPIRY_DATE=$(date -d "@$EXPIRY" 2>/dev/null || echo "Invalid timestamp")
  echo "Expiry Date: $EXPIRY_DATE"
fi

if [ "$ISSUED_AT" != "N/A" ]; then
  ISSUED_DATE=$(date -d "@$ISSUED_AT" 2>/dev/null || echo "Invalid timestamp")
  echo "Issued Date: $ISSUED_DATE"
fi

echo ""
echo "=== Broker Service Status ==="
echo "Realm: $BROKER_REALM"
echo "Client ID: $BROKER_CLIENT_ID"
echo "Token Type: Bearer"