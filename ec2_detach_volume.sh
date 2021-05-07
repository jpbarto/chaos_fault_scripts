#!/usr/bin/env bash

###############################################################################################
#
# The following shell script uses the AWS CLI to forcefully detach a non-root volume from a 
# running EC2 instance.  In preliminary testing this produced a read-only filesystem on a 
# running host with the volume mounted.  This is intended to grossly simulate communication
# errors with the EBS volume from an EC2 instance.
#
# Note that this script will NOT detach the root volume from an EC2 instance.
#
###############################################################################################

set -e

REGION=eu-west-1
VOLUME=vol-03e1234a1234a9e1c

aws ec2 detach-volume --volume-id $VOLUME --region $REGION --force
