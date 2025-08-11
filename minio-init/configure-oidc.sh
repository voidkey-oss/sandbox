#!/bin/bash
set -e

echo "Configuring MinIO OIDC for broker authentication..."

# Configure MinIO to accept OIDC tokens from Keycloak broker realm
# Note: Using broker-service client_id since that's the actual client in Keycloak
# MinIO will validate tokens issued by this client against the broker realm
mc admin config set local identity_openid \
  config_url="http://keycloak:8080/realms/broker/.well-known/openid-configuration" \
  client_id="broker-service" \
  client_secret="broker-secret-12345" \
  claim_name="preferred_username" \
  scopes="openid" \
  redirect_uri_dynamic="on"

# Note: MinIO restart will be handled by the container orchestration
echo "OIDC configuration applied successfully."
echo "MinIO will restart automatically or can be restarted via container orchestration."

# Wait a moment for any internal configuration reload
echo "Waiting for configuration to take effect..."
sleep 5

# Verify OIDC configuration
echo "Verifying OIDC configuration..."
mc admin config get local identity_openid

echo ""
echo "=== MinIO OIDC Configuration Complete ==="
echo "MinIO will now accept OIDC tokens from the broker realm"
echo "The role ARN printed above should be added to the broker configuration"
echo ""