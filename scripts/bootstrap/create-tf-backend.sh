#!/bin/bash
# SSE-S3 en vez de KMS — excepción de bootstrap
# Este bucket existe antes que Terraform y sus CMKs
# Todo el resto de la infraestructura usa KMS CMK

ENVIRONMENT=$1
BUCKET_NAME=$2
AWS_REGION=$3
DYNAMODB_TABLE_NAME=$4

mi_lista_variables=(
    "ENVIRONMENT"
    "BUCKET_NAME"
    "AWS_REGION"
    "DYNAMODB_TABLE_NAME"
)
for var in "${mi_lista_variables[@]}"; do
    if [ -z "${!var}" ]; then
        echo Error: La variable $var no está definida
        exit 1
    fi
done

echo "Crear el bucket S3 para el backend de Terraform"
aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION

echo "versioning del bucket S3" 
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

echo "public access block del bucket S3"
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "cifrado del bucket S3"
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

echo "crear la tabla DynamoDB para el backend de Terraform"
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $AWS_REGION


if aws s3 ls s3://$BUCKET_NAME 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists, skipping..."
else
    aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
fi

if aws dynamodb describe-table --table-name $DYNAMODB_TABLE_NAME 2>/dev/null; then
    echo "Table $DYNAMODB_TABLE_NAME already exists, skipping..."
else
    aws dynamodb create-table \
        --table-name $DYNAMODB_TABLE_NAME \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region $AWS_REGION
fi