const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');

// Initialize clients with LocalStack endpoint
const LOCALSTACK_HOSTNAME = process.env.LOCALSTACK_HOSTNAME || 'localhost';
const endpoint = `http://${LOCALSTACK_HOSTNAME}:4566`;

const s3Client = new S3Client({
    endpoint,
    region: 'us-east-1',
    credentials: { accessKeyId: 'test', secretAccessKey: 'test' },
    forcePathStyle: true
});

const ddbClient = new DynamoDBClient({
    endpoint,
    region: 'us-east-1',
    credentials: { accessKeyId: 'test', secretAccessKey: 'test' }
});

const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);

exports.handler = async (event) => {
    try {
        const timestamp = new Date();
        const formattedDate = timestamp.toISOString()
            .replace(/T/, ' ')
            .replace(/\..+/, '');
        
        const fileName = `${formattedDate} - test file.txt`;
        const bucketName = process.env.BUCKET_NAME;
        const filePath = `${bucketName}/${fileName}`;
        
        // Create and upload file to S3
        await s3Client.send(new PutObjectCommand({
            Bucket: bucketName,
            Key: fileName,
            Body: `This file was created at ${formattedDate}`
        }));
        
        // Record the file creation in DynamoDB
        await ddbDocClient.send(new PutCommand({
            TableName: process.env.TABLE_NAME,
            Item: {
                filePath: filePath,
                createdAt: formattedDate
            }
        }));
        
        console.log(`Successfully created file ${fileName} and recorded in DynamoDB`);
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Success', filePath })
        };
    } catch (error) {
        console.error('Error:', error);
        throw error;
    }
};
