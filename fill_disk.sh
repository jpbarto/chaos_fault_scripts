#!/usr/bin/env bash

###############################################################################################
#
# The following shell script uses AWS Systems Manager to execute multiple instances of DD in 
# order to create large files (each approximately 12 GB in size) with the objective being to
# fill the disk to capacity.
#
# Output for the shell script that executes on the EC2 instance can be obtained from Systems 
# Manager Run Command either through the AWS Console or using the AWS CLI.
#
###############################################################################################

set -e

EC2_INSTANCE_ID="i-0ade12e1fef123e24"
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
