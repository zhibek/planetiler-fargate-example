#!/usr/bin/env bash

# Stop on any error
set -e

# Use env vars or defaults for input variables
APP_NAME="${APP_NAME:=planetiler-fargate-example}"
TASK_NAME="${TASK_NAME:=planetiler-task}"
STAGE="${STAGE:=dev}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:=eu-west-1}"
NO_FOLLOW=${NO_FOLLOW:=}

# Validate input variables are set
[ -z "${APP_NAME}" ] && echo "ERROR: APP_NAME env var must be set!" && exit 1;
[ -z "${TASK_NAME}" ] && echo "ERROR: TASK_NAME env var must be set!" && exit 1;

# Build STACK_NAME
STACK_NAME="${APP_NAME}-${STAGE}"

# Set BASEDIR holding script path
BASEDIR=$(dirname "$0")

# Check AWS auth
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  echo "ERROR: AWS authentication requires AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY env vars are set!"
  exit 1
fi

echo "STACK_NAME=${STACK_NAME}"
echo "TASK_NAME=${TASK_NAME}"
echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}"
echo "NO_FOLLOW=${NO_FOLLOW}"
echo ""

# Find AWS Subnet ID
echo "Finding AWS Subnet ID..."
AWS_SUBNET_ID=$(aws ec2 describe-subnets \
  --max-items 1 \
  --filter Name=default-for-az,Values=true \
  --query Subnets[].[SubnetId] \
  --output text \
  | head -n 1 \
)
echo "AWS_SUBNET_ID=${AWS_SUBNET_ID}"
if [ -z "${AWS_SUBNET_ID}" ]; then
  echo "ERROR: Could not find AWS Subnet ID!"
  exit 1
fi

# Find AWS Security Group
echo "Finding AWS Security Group..."
AWS_SECURITYGROUP_ID=$(aws ec2 describe-security-groups \
  --max-items 1 \
  --filter Name=group-name,Values=default \
  --query SecurityGroups[].[GroupId] \
  --output text \
  | head -n 1 \
)
echo "AWS_SECURITYGROUP_ID=${AWS_SECURITYGROUP_ID}"
if [ -z "${AWS_SECURITYGROUP_ID}" ]; then
  echo "ERROR: Could not find AWS Security Group ID!"
  exit 1
fi

# Run ECS task
echo "Running task with ECS..."
TASK_RUN_ARN=$(aws ecs run-task \
  --cluster ${STACK_NAME} \
  --task-definition ${TASK_NAME} \
  --launch-type FARGATE \
  --network-configuration '{"awsvpcConfiguration": {"subnets": ["'"${AWS_SUBNET_ID}"'"],"securityGroups": ["'"${AWS_SECURITYGROUP_ID}"'"],"assignPublicIp": "ENABLED"}}' \
  --query tasks[].[taskArn] \
  --output text \
)
TASK_RUN_ID=$(echo ${TASK_RUN_ARN} | sed 's/.*\///')
echo "TASK_RUN_ID=${TASK_RUN_ID}"

# Pause until task run is complete in FOLLOW mode
if [ -z "${NO_FOLLOW}" ]; then
  echo "Waiting for ECS task to start running..."
  aws ecs wait tasks-running \
    --cluster ${STACK_NAME} \
    --tasks ${TASK_RUN_ID}

  echo "ECS task running. Following logs..."
  aws logs tail \
    ${STACK_NAME} \
    --log-stream-names "fargate/${TASK_NAME}/${TASK_RUN_ID}" \
    --follow &

  aws ecs wait tasks-stopped \
    --cluster ${STACK_NAME} \
    --tasks ${TASK_RUN_ID}
  kill $!  # Kill "aws logs tail" background task
  echo "ECS task run complete!"
fi


# Keep this statement until the end!
echo "***** Run complete! *****"
