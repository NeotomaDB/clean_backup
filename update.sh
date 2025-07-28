#!/bin/bash

# update.sh - Update the neotoma sanitization infrastructure

set -e

STACK_NAME="neotoma-batch-sanitizer"
PARAMETERS_FILE="infrastructure/parameters.json"
TEMPLATE_FILE="infrastructure/batch-infrastructure.yaml"

echo "🔄 Updating Neotoma Batch Sanitizer Infrastructure"
echo "Stack Name: $STACK_NAME"
echo ""

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    echo "❌ Stack '$STACK_NAME' does not exist. Use deploy.sh to create it first."
    exit 1
fi

echo "Updating CloudFormation stack..."
aws cloudformation update-stack \
    --stack-name "$STACK_NAME" \
    --template-body "file://$TEMPLATE_FILE" \
    --parameters "file://$PARAMETERS_FILE" \
    --capabilities CAPABILITY_IAM

echo "✅ Stack update initiated. Monitoring progress..."

# Monitor the update
aws cloudformation wait stack-update-complete --stack-name "$STACK_NAME" && {
    echo "🎉 Stack updated successfully!"
    echo ""
    echo "📋 Stack Outputs:"
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' --output table
} || {
    echo "❌ Stack update failed. Checking events..."
    aws cloudformation describe-stack-events --stack-name "$STACK_NAME" --query 'StackEvents[?ResourceStatus==`UPDATE_FAILED`].[Timestamp,LogicalResourceId,ResourceStatusReason]' --output table
}