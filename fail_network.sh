#!/usr/bin/env bash

###############################################################################################
#
# The following shell script uses AWS Systems Manager to install and use tcconfig to manipulate
# the OS network stack to drop 30% of the packets sent to a target IP address.
#
# https://tcconfig.readthedocs.io/en/latest/index.html
#
# To do this the shell script will use the Run Command capability of Systems Manager to
# execute a shell script on the specified EC2 instance.  The SSM Agent on the EC2 instance 
# will then download, install, and use `tcconfig` to insert a rule which drops 30% of packets
# sent to the target IP address.  The script will allow this to persist for 5 minutes before
# deleting the rule and allowing the EC2 instance to resume normal operation.
#
# Output for the shell script that executes on the EC2 instance can be obtained from Systems 
# Manager Run Command either through the AWS Console or using the AWS CLI.
#
###############################################################################################

set -e

EC2_INSTANCE_ID="i-01ed12345ec123456"
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
