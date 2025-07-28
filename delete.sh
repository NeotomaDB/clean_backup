#!/bin/bash

# delete.sh - Delete the neotoma sanitization infrastructure

set -e

STACK_NAME="neotoma-batch-sanitizer"

echo "🗑️  Deleting Neotoma Batch Sanitizer Infrastructure"
echo "Stack Name: $STACK_NAME"
echo ""

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    echo "❌ Stack '$STACK_NAME' does not exist."
    exit 1
fi

# Confirm deletion
read -p "Are you sure you want to delete the stack '$STACK_NAME'? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deletion cancelled."
    exit 1
fi

echo "Deleting CloudFormation stack..."
aws cloudformation delete-stack --stack-name "$STACK_NAME"

echo "✅ Stack deletion initiated. Waiting for completion..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" && {
    echo "🎉 Stack deleted successfully!"
} || {
    echo "❌ Stack deletion failed. Check the AWS Console for details."
    aws cloudformation describe-stack-events --stack-name "$STACK_NAME" --query 'StackEvents[0:10].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]' --output table
}