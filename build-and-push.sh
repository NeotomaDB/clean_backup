!/bin/bash

# Configuration - UPDATE THESE VALUES
AWS_REGION="us-east-2"  # Change to your region
AWS_ACCOUNT_ID="417278330808"  # Change to your account ID
REPOSITORY_NAME="neotoma-sanitizer"
IMAGE_TAG="latest"

set -e

echo "Building neotoma-sanitizer Docker image..."

# Build the image
echo "Building Docker image..."
docker build -f batch.Dockerfile -t ${REPOSITORY_NAME}:${IMAGE_TAG} .

# Create ECR repository if it doesn't exist
echo "Creating ECR repository if needed..."
aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} --region ${AWS_REGION} 2>/dev/null || \
aws ecr create-repository --repository-name ${REPOSITORY_NAME} --region ${AWS_REGION}

# Get login token and login
echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Tag image for ECR
docker tag ${REPOSITORY_NAME}:${IMAGE_TAG} \
${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${IMAGE_TAG}

# Push to ECR
echo "Pushing image to ECR..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${IMAGE_TAG}

echo "✓ Image pushed successfully!"
echo "✓ Image URI: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${IMAGE_TAG}"
echo ""
echo "Next steps:"
echo "1. Update the CloudFormation template with this image URI"
echo "2. Deploy the infrastructure"