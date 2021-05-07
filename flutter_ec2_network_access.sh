#!/usr/bin/env bash

###############################################################################################
#
# The following shell script takes an EC2 instance ID and then, using a NACL, allows and denies
# IP egress / ingress from and to the EC2 instance.
#
# To do this the script will create a new NACL that blocks all traffic to or from the IP
# address of the EC2 instance.  The NACL will then be associated with the subnet containing
# the EC2 instance.  The script will then, for $RUN_TIME seconds, continually create and
# delete entries in the NACL to allow or deny network activity to the EC2 instance.  The script
# will first deny traffic for a random number of seconds (1 to 10 seconds) and then allow
# traffic for a random number of seconds, until $RUN_TIME has been reached.
#
# After $RUN_TIME seconds the script will restore the original NACL association of the subnet
# and delete the NACL that was created for the test.
#
###############################################################################################

set -e

# identify the EC2 instance ID to be targeted by NACL rules
INSTANCE_ID=$1

# detect metadata about the instance and its environment
IP_ADDR=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].NetworkInterfaces[0].PrivateIpAddress' --output text)
VPC_ID=$(aws ec2 describe-instances --instance-ids $INST --query 'Reservations[0].Instances[0].VpcId' --output text)
SUBNET_ID=$(aws ec2 describe-instances --instance-ids $INST --query 'Reservations[0].Instances[0].NetworkInterfaces[0].SubnetId' --output text)
ORIG_NACL_ID=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$SUBNET_ID --query 'NetworkAcls[0].NetworkAclId' --output text)
ORIG_NACL_ASSOC_ID=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$SUBNET_ID --query 'NetworkAcls[0].Associations' | jq -r --arg snid $SUBNET_ID 'map(select(.SubnetId==$snid))[0].NetworkAclAssociationId')

# limit the time this script will run
RUN_TIME=300 # execute for $RUN_TIME seconds
STOP_TIME=$(( `date +%s` + $RUN_TIME ))

function print_log {
    echo [`date`]: $1
}

# function to add blocking NACL entries to a NACL
function block_ip {
    aws ec2 create-network-acl-entry --network-acl-id $1 --rule-number 100 --cidr-block "$2/32" --egress --protocol all --port-range From=0,To=65535 --rule-action deny
    aws ec2 create-network-acl-entry --network-acl-id $1 --rule-number 110 --cidr-block "$2/32" --ingress --protocol all --port-range From=0,To=65535 --rule-action deny
}

# function to remove blocking NACL entries from a NACL
function allow_ip {
    aws ec2 delete-network-acl-entry --network-acl-id $1 --rule-number 100 --egress
    aws ec2 delete-network-acl-entry --network-acl-id $1 --rule-number 110 --ingress
}

print_log "Preparing to flutter network traffic to / from $INSTANCE_ID for $RUN_TIME seconds"
NEW_NACL_ID=$(aws ec2 create-network-acl --vpc-id $VPC_ID --query 'NetworkAcl.NetworkAclId' --output text)
print_log "Created a network access control list with ID $NEW_NACL_ID"

print_log "Targeting instance ENI with IP address $IP_ADDR"
NEW_NACL_ASSOC_ID=$(aws ec2 replace-network-acl-association --association-id $ORIG_NACL_ASSOC_ID --network-acl-id $NEW_NACL_ID --query 'NewAssociationId' --output text)
while [[ `date +%s` < $STOP_TIME ]]
do
    SLEEP_TIME=$(( ( $RANDOM % 10 ) + 1 ))
    print_log "Disabling traffic to / from $IP_ADDR for $SLEEP_TIME seconds"
    block_ip $NEW_NACL_ID $IP_ADDR
    sleep $SLEEP_TIME

    SLEEP_TIME=$(( ( $RANDOM % 10 ) + 1 ))
    print_log "Enabling traffic to / from $IP_ADDR for $SLEEP_TIME seconds"
    allow_ip $NEW_NACL_ID $IP_ADDR
    sleep $SLEEP_TIME
done

print_log "Terminating test"
NEW_OLD_NACL_ASSOC_ID=$(aws ec2 replace-network-acl-association --association-id $NEW_NACL_ASSOC_ID --network-acl-id $ORIG_NACL_ID)
aws ec2 delete-network-acl --network-acl-id $NEW_NACL_ID
print_log "Deleted the network access control list with ID $NEW_NACL_ID"
