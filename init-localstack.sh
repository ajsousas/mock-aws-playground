#!/bin/bash

set -e
echo "Starting initialization script..."

# Debug information
echo "Current directory: $(pwd)"
echo "Listing /etc/localstack/init/ready.d:"
ls -la /etc/localstack/init/ready.d
echo "Listing /infrastructure:"
ls -la /infrastructure
echo "Listing /infrastructure/lambda:"
ls -la /infrastructure/lambda

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
max_retries=30
retries=0
while [ $retries -lt $max_retries ]; do
    health_status=$(curl -s "http://localhost:4566/_localstack/health")
    if echo "$health_status" | grep -q '"s3": "available"' && \
       echo "$health_status" | grep -q '"lambda": "available"' && \
       echo "$health_status" | grep -q '"dynamodb": "available"' && \
       echo "$health_status" | grep -q '"cloudformation": "available"' && \
       echo "$health_status" | grep -q '"logs": "available"' && \
       echo "$health_status" | grep -q '"events": "available"' && \
       echo "$health_status" | grep -q '"iam": "available"'; then
        echo "All required services are ready!"
        break
    fi
    echo "Waiting for services to be ready... (attempt $((retries + 1))/$max_retries)"
    retries=$((retries + 1))
    sleep 2
done

if [ $retries -eq $max_retries ]; then
    echo "Timeout waiting for LocalStack services to be ready. Current health status:"
    curl -s "http://localhost:4566/_localstack/health" | python3 -m json.tool
    exit 1
fi

echo "LocalStack is ready! Packaging Lambda function..."

# Install dependencies and package Lambda function
cd /infrastructure/lambda
npm install --production
zip -r /tmp/function.zip * -x "**/node_modules/aws-sdk/**" -x "**/*.md" -x "**/.git*"

# Create a temporary bucket for Lambda code and upload the package
awslocal s3 mb s3://lambda-code-bucket
awslocal s3 cp /tmp/function.zip s3://lambda-code-bucket/lambda/function.zip

echo "Lambda function packaged and uploaded. Deploying CloudFormation stack..."

# Deploy CloudFormation stack
awslocal cloudformation create-stack \
    --stack-name demo-stack \
    --template-body file:///infrastructure/template.yaml \
    --capabilities CAPABILITY_IAM

echo "Waiting for stack creation to complete..."
awslocal cloudformation wait stack-create-complete --stack-name demo-stack

echo "Stack deployment completed!"

# Wait a moment for resources to be available
sleep 5

# Print stack outputs and resource status
echo "Stack outputs:"
awslocal cloudformation describe-stacks --stack-name demo-stack
echo "Stack resources:"
awslocal cloudformation list-stack-resources --stack-name demo-stack
