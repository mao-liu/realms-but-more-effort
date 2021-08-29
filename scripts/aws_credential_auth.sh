#!/bin/bash
set -e

AWS_USER_NAME=`aws sts get-caller-identity --profile mfa | jq -r .Arn | cut -d '/' -f 2`
AWS_MFA_SERIAL=`aws iam list-mfa-devices --profile mfa --user $AWS_USER_NAME | jq -r .MFADevices[0].SerialNumber`

echo -n "Please Enter MFA token for ${AWS_USER_NAME} (${AWS_MFA_SERIAL}): " && read MFA_TOKEN
CRED=`aws sts get-session-token --profile mfa --serial-number $AWS_MFA_SERIAL --token-code $MFA_TOKEN`

# AWS CDK does not support credential_process... we'll have to push the session credentials to all profiles
#echo "Exporting MFA session credentials to ~/.aws/credentials_mfa_session.json"
#echo $CRED | jq -r .Credentials | jq -r '. |= .+ {"Version": 1}' > ~/.aws/credentials_mfa_session.json

AWS_ACCESS_KEY_ID=`echo $CRED | jq -r .Credentials.AccessKeyId`
AWS_SECRET_ACCESS_KEY=`echo $CRED | jq -r .Credentials.SecretAccessKey`
AWS_SESSION_TOKEN=`echo $CRED | jq -r .Credentials.SessionToken`
echo "Authentication successful."

for profile in game-provisioning game-1; do
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile $profile
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile $profile
    aws configure set aws_session_token $AWS_SESSION_TOKEN --profile $profile
    echo "Saved credentials to Profile ${profile}"
done
