#!/bin/bash
set -e

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
until mc alias set local http://minio:9000 minioadmin minioadmin123; do
  echo "MinIO not ready yet, waiting..."
  sleep 5
done

echo "MinIO is ready, configuring..."

# Create broker policy - allows managing users and creating service accounts (credential minting) <-- need to make this less permissive in the future, this is admin status for testing purposes
cat > /tmp/broker-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "admin:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Create client policy - allows full S3 operations on assigned buckets
cat > /tmp/client-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::voidkey-data",
        "arn:aws:s3:::voidkey-data/*"
      ]
    }
  ]
}
EOF


# Create policies
echo "Creating broker policy..."
mc admin policy create local broker-policy /tmp/broker-policy.json

echo "Creating client policy..."
mc admin policy create local client-policy /tmp/client-policy.json

# Create broker-service policy for OIDC token mapping
# MinIO maps OIDC tokens based on preferred_username claim, so we need a policy named "broker-service"
echo "Creating broker-service policy for OIDC mapping..."
mc admin policy create local broker-service /tmp/broker-policy.json

# Create users
echo "Creating broker user..."
mc admin user add local broker-user broker-password-123

echo "Creating client user..."
mc admin user add local client-user client-password-456

# Assign policies to users
echo "Assigning broker policy to broker user..."
mc admin policy attach local broker-policy --user broker-user

echo "Assigning client policy to client user..."
mc admin policy attach local client-policy --user client-user

# Create a test bucket
echo "Creating test bucket..."
mc mb local/voidkey-data || echo "Bucket already exists"

# Set bucket policy to allow client access
cat > /tmp/bucket-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::*:user/client-user"
      },
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::voidkey-data/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::*:user/client-user"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::voidkey-data"
    }
  ]
}
EOF

echo "Setting bucket policy..."
mc anonymous set-json /tmp/bucket-policy.json local/voidkey-data || echo "Could not set bucket policy, continuing..."

echo "MinIO configuration complete!"
echo ""
echo "=== Configuration Summary ==="
echo "MinIO Console: http://localhost:9001"
echo "MinIO API: http://localhost:9000"
echo "Root credentials: minioadmin / minioadmin123"
echo ""
echo "Broker User: broker-user / broker-password-123"
echo "  - Policy: broker-policy (Currently admin:* for testing - will be scoped in production)"
echo ""
echo "Client User: client-user / client-password-456"
echo "  - Policy: client-policy (Full S3 access to voidkey-data bucket)"
echo ""
echo "Test bucket: voidkey-data"