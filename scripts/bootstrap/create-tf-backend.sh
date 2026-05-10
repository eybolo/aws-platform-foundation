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
echo "Variables: ENVIRONMENT=$ENVIRONMENT BUCKET_NAME=$BUCKET_NAME"