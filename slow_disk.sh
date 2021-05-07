#!/usr/bin/env bash

# Based on https://serverfault.com/questions/523509/linux-how-to-simulate-hard-disk-latency-i-want-to-increase-iowait-value-withou

set -e

EC2_INSTANCE_ID="i-01d92ebe26df0718c"
MOUNT_POINT='/opt'
DELAY=200 # ms of delay to add to disk read / write
TEST_DURATION=300 # seconds to wait before undoing changes
REGION="eu-west-2"

aws ssm send-command \
    --document-name "AWS-RunShellScript" \
    --targets "Key=instanceids,Values=$EC2_INSTANCE_ID" \
    --region $REGION \
    --parameters 'commands=[
    "echo Create a temporary loopback device...",
    "dd if=/dev/zero of=/tmp/500M-of-zeroes bs=1024k count=500",
    "LOOPDEV=$(losetup --show --find /tmp/500M-of-zeroes)",
    "DEVSIZE=$(blockdev --getsize $LOOPDEV)",
    "echo 0 $DEVSIZE delay $LOOPDEV 0 '$DELAY' | dmsetup create dm-slow",
    "mkfs.ext4 /dev/mapper/dm-slow",
    "mount /dev/mapper/dm-slow '$MOUNT_POINT'",
    "echo Sleeping for '$TEST_DURATION' seconds...",
    "sleep '$TEST_DURATION'",
    "echo Unmounting drive...",
    "umount '$MOUNT_POINT'"
    ]'
