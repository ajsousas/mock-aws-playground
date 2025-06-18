# LocalStack AWS Services Demo

This project demonstrates how to use LocalStack to mock AWS services locally for development and testing purposes. It creates a Lambda function that runs every 5 minutes to create timestamped files in S3 and record their details in DynamoDB.

## Prerequisites

- Docker and Docker Compose
- AWS CLI
- Node.js (v22 or later)

## Project Structure

```
.
├── docker-compose.yml
├── init-localstack.sh
├── infrastructure/
│   ├── template.yaml
│   └── lambda/
│       ├── index.js
│       └── package.json
└── README.md
```

## Getting Started

1. Start LocalStack with automatic CloudFormation deployment:
   ```bash
   docker-compose up -d
   ```

2. The init script will automatically:
   - Wait for LocalStack to be ready
   - Deploy the CloudFormation stack
   - Create the S3 bucket, DynamoDB table, and Lambda function

## Using AWS CLI with LocalStack

All AWS CLI commands will use the us-east-1 (N. Virginia) region. To interact with LocalStack using AWS CLI, use the `--endpoint-url` parameter:

```bash
# List S3 buckets
aws --endpoint-url=http://localhost:4566 --region us-east-1 s3 ls

# List DynamoDB tables
aws --endpoint-url=http://localhost:4566 --region us-east-1 dynamodb list-tables

# List Lambda functions
aws --endpoint-url=http://localhost:4566 --region us-east-1 lambda list-functions

# Invoke Lambda manually
aws --endpoint-url=http://localhost:4566 --region us-east-1 lambda invoke \
    --function-name demo-file-creator \
    --payload '{}' response.json
```

Alternatively, you can use the `awslocal` command inside the container:

```bash
docker exec localstack-demo awslocal s3 ls
# OR
docker exec -it localstack-demo sh
awslocal s3 ls
awslocal dynamodb list-tables
```

## Viewing Resources

1. S3 files:
   ```bash
   # List files in the bucket
   aws --endpoint-url=http://localhost:4566 --region us-east-1 s3 ls s3://demo-files-bucket

   # Download a specific file (replace filename)
   aws --endpoint-url=http://localhost:4566 --region us-east-1 s3 cp \
       s3://demo-files-bucket/2025-06-17\ 10:30:00\ -\ test\ file.txt ./
   ```

2. DynamoDB records:
   ```bash
   # Scan all records
   aws --endpoint-url=http://localhost:4566 --region us-east-1 dynamodb scan \
       --table-name demo-files-registry

   # Query files created in a specific date (replace the date)
   aws --endpoint-url=http://localhost:4566 --region us-east-1 dynamodb query \
       --table-name demo-files-registry \
       --key-condition-expression "begins_with(createdAt, :date)" \
       --expression-attribute-values '{":date": {"S": "2025-06-17"}}'
   ```

3. Lambda logs:
   ```bash
   # Get log group
   aws --endpoint-url=http://localhost:4566 --region us-east-1 logs describe-log-groups

   # Get log streams
   aws --endpoint-url=http://localhost:4566 --region us-east-1 logs describe-log-streams \
       --log-group-name /aws/lambda/demo-file-creator

   # Get logs
   aws --endpoint-url=http://localhost:4566 --region us-east-1 logs get-log-events \
       --log-group-name /aws/lambda/demo-file-creator \
       --log-stream-name <stream-name>
   ```

## Cleanup

To stop and remove all resources:

```bash
docker-compose down
```
