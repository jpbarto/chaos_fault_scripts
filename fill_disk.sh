#!/usr/bin/env bash

set -e

EC2_INSTANCE_ID="i-0ade35e7fef304e24"
TEST_DURATION=300
REGION="eu-west-3"

aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --targets "Key=instanceids,Values=$EC2_INSTANCE_ID" \
    --region $REGION \
    --parameters 'commands=[
    "echo Filling disk with 120 GB of 0 using dd...",
    "cd /mnt",
    "for i in 0 1 2 3 4 5 6 7 8 9",
    "do",
    "dd if=/dev/zero of=./zero-filler.$i bs=256M count=50 &",
    "done",
    "df -h"
    ]'
