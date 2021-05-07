#!/usr/bin/env bash

set -e

EC2_INSTANCE_ID="i-0f42216e65df5e1d9"
DISK_DEV='/dev/nvme0n1p1'
TEST_DURATION=300
REGION="eu-west-2"

aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --targets "Key=instanceids,Values=$EC2_INSTANCE_ID" \
    --region $REGION \
    --parameters 'commands=[
    "echo Forcing disk unmount...",
    "umount -fl '$DISK_DEV'",
    "echo Sleeping for '$TEST_DURATION' seconds...",
    "sleep '$TEST_DURATION'",
    "echo Restarting system...",
    "shutdown -r now"
    ]'
