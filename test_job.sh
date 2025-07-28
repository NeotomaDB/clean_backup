#!/bin/bash

# test-job.sh - Submit a test job manually

set -e

STACK_NAME="neotoma-batch-sanitizer"

echo "🧪 Submitting Test Job"
echo "====================="
echo ""

# Check if stack exists
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    echo "❌ Stack '$STACK_NAME' does not exist. Deploy it first."
    exit 1
fi

# Get job queue and definition ARNs
JOB_QUEUE_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`JobQueueArn`].OutputValue' --output text)
JOB_DEFINITION_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].Outputs[?OutputKey==`JobDefinitionArn`].OutputValue' --output text)

if [ -z "$JOB_QUEUE_ARN" ] || [ -z "$JOB_DEFINITION_ARN" ]; then
    echo "❌ Could not retrieve job queue or job definition ARNs"
    exit 1
fi

# Generate job name with timestamp
JOB_NAME="test-sanitization-$(date +%Y%m%d-%H%M%S)"

echo "Job Queue: $JOB_QUEUE_ARN"
echo "Job Definition: $JOB_DEFINITION_ARN"
echo "Job Name: $JOB_NAME"
echo ""

# Submit the job
echo "Submitting job..."
JOB_ID=$(aws batch submit-job \
    --job-name "$JOB_NAME" \
    --job-queue "$JOB_QUEUE_ARN" \
    --job-definition "$JOB_DEFINITION_ARN" \
    --query 'jobId' --output text)

echo "✅ Job submitted successfully!"
echo "Job ID: $JOB_ID"
echo ""
echo "Monitor the job with:"
echo "  aws batch describe-jobs --jobs $JOB_ID"
echo ""
echo "Or check the logs in CloudWatch:"
echo "  https://console.aws.amazon.com/cloudwatch/home#logsV2:log-groups"