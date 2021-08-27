#!/bin/bash

# set region
aws configure --profile game-provisioning set region ap-southeast-2
aws configure --profile game set region ap-southeast-2


# set access key for MFA sessions
echo -n "Set Access Key for Profile mfa? (y/n): " && read SET_ACCESS_KEY
if [[ $SET_ACCESS_KEY == "y" ]]; then
    echo -n "AWS_ACCESS_KEY_ID=" && read AWS_ACCESS_KEY_ID
    echo -n "AWS_SECRET_ACCESS_KEY=" && read AWS_SECRET_ACCESS_KEY
    aws configure --profile mfa set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure --profile mfa set aws_secret_access_key $AWS_SECRET_ACCESS_KEY

    echo -n "Testing access key"
    aws sts get-caller-identity --profile mfa
fi
