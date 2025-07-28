#!/bin/bash

# status.sh - Check the status of the infrastructure and recent jobs

set -e

STACK_NAME="neotoma-batch-sanitizer"

echo "📊 Neotoma Batch Sanitizer Status"
echo "=================================="
echo ""

# Check stack status
echo "🏗️  CloudFormation Stack Status:"
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text)
    echo "   Status: $STACK_STATUS"
    
    if [ "$STACK_STATUS" = "CREATE_COMPLETE" ] || [ "$STACK_STATUS" = "UPDATE_COMPLETE" ]; then
        echo "   ✅ Stack is healthy"
        
        # Get job queue name
        JOB_QUEUE_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`JobQueueArn`].OutputValue' --output text)
        
        if [ ! -z "$JOB_QUEUE_ARN" ]; then
            echo ""
            echo "📋 Recent Batch Jobs:"
            aws batch list-jobs --job-queue "$JOB_QUEUE_ARN" --job-status SUCCEEDED --max-items 5 --query 'jobList[*].[jobName,jobStatus,createdAt]' --output table 2>/dev/null || echo "   No recent successful jobs"
            
            echo ""
            echo "🏃 Running Jobs:"
            aws batch list-jobs --job-queue "$JOB_QUEUE_ARN" --job-status RUNNING --query 'jobList[*].[jobName,jobStatus,createdAt]' --output table 2>/dev/null || echo "   No running jobs"
        fi
        
        # Check EventBridge rule
        echo ""
        echo "⏰ Scheduled Rule Status:"
        aws events list-rules --query 'Rules[?contains(Description, `sanitization`)].[Name,State,ScheduleExpression]' --output table 2>/dev/null || echo "   No rules found"
        
        # Check S3 bucket
        echo ""
        echo "📦 Recent S3 Uploads:"
        aws s3 ls s3://neotomaprimarybackup/ --recursive --human-readable | tail -5 || echo "   Could not access S3 bucket"
        
    else
        echo "   ⚠️  Stack status: $STACK_STATUS"
    fi
else
    echo "   ❌ Stack does not exist"
fi