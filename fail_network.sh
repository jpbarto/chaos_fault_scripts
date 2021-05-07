#!/usr/bin/env bash

set -e

EC2_INSTANCE_ID="i-01ed17172ec400432"
TARGET_IP="10.0.1.164"
TEST_DURATION=300
REGION="eu-central-1"

aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --targets "Key=instanceids,Values=$EC2_INSTANCE_ID" \
    --region $REGION \
    --parameters 'commands=[
    "yum install -q -y python3-pip iproute-tc",
    "pip3 install -qq tcconfig",
    "echo Current tc rules...",
    "tcshow eth0",
    "echo Configuring packet loss...",
    "tcset eth0 --loss 30.0% --network '$TARGET_IP'",
    "tcshow eth0",
    "echo Sleeping for '$TEST_DURATION' seconds...",
    "sleep '$TEST_DURATION'",
    "echo Clearing tc rules...",
    "tcdel eth0 --all",
    "tcshow eth0"
    ]'
