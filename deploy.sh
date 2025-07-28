#!/bin/bash

# deploy.sh - Deploy the neotoma sanitization and dump infrastructure

set -e

STACK_NAME="neotoma-batch-sanitizer"
PARAMETERS_FILE="infrastructure/parameters.json"
TEMPLATE_FILE="infrastructure/batch-infrastructure.yaml"

echo "🚀 Deploying Neotoma Batch Sanitizer Infrastructure"
echo "Stack Name: $STACK_NAME"
echo "Template: $TEMPLATE_FILE"
echo "Parameters: $PARAMETERS_FILE"
echo ""

# Check if parameters file exists
if [ ! -f "$PARAMETERS_FILE" ]; then
    echo "❌ Parameters file not found: $PARAMETERS_FILE"
    echo "Please create the parameters file first."
    exit 1
fi

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Template file not found: $TEMPLATE_FILE"
    exit 1
fi

# Check if stack already exists
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    echo "⚠️  Stack already exists. Use update.sh to update it or delete.sh to remove it first."
    exit 1
fi

echo "Creating CloudFormation stack..."
aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE_FILE" \
    --parameters "file://$PARAMETERS_FILE" \
    --capabilities CAPABILITY_IAM

echo "✅ Stack creation initiated. Monitoring progress..."
echo "You can also monitor in the AWS Console: https://console.aws.amazon.com/cloudformation/"
echo ""

# Monitor the deployment
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" && {
    echo "🎉 Stack created successfully!"
    echo ""
    echo "📋 Stack Outputs:"
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' --output table
} || {
    echo "❌ Stack creation failed. Checking events..."
    aws cloudformation describe-stack-events --stack-name "$STACK_NAME" --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[Timestamp,LogicalResourceId,ResourceStatusReason]' --output table
}