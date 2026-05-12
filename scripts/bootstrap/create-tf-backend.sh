#!/bin/bash
# SSE-S3 en vez de KMS — excepción de bootstrap
# Este bucket existe antes que Terraform y sus CMKs
# Todo el resto de la infraestructura usa KMS CMK

#Quitamos el dynamoDB porque estamos usando el lock del S3 bucket

ENVIRONMENT=$1
BUCKET_NAME=$2
AWS_REGION=$3

mi_lista_variables=(
    "ENVIRONMENT"
    "BUCKET_NAME"
    "AWS_REGION"
)
for var in "${mi_lista_variables[@]}"; do
    if [ -z "${!var}" ]; then
        echo Error: La variable $var no está definida
        exit 1
    fi
done

echo "Crear el bucket S3 para el backend de Terraform"
if aws s3 ls s3://$BUCKET_NAME 2>/dev/null; then
    echo "Bucket $BUCKET_NAME already exists, skipping..."
else
    aws s3 mb s3://$BUCKET_NAME --region $AWS_REGION
fi

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