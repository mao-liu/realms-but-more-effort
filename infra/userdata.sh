#!/bin/bash

INSTALL_PATH="/var/realms"
INSTALL_USER="ssm-user"

GIT_REPO="git@github.com:mao-liu/realms-but-more-effort.git"
GIT_DEPLOY_KEY_SSM_PATH="/realms/inputs/github_deploy_key"
GIT_DEPLOY_KEY_LOCAL_PATH="/root/.ssh/github_deploy_key"
GIT_BRANCH="feature/infra-core"

AWS_REGION="ap-southeast-2"

yum install -y git jq

mkdir -p ~/.ssh

# get the ssh deploy key for the github repo
aws ssm get-parameter \
    --name ${GIT_DEPLOY_KEY_SSM_PATH} \
    --region ${AWS_REGION} \
    --with-decryption \
    | jq -r .Parameter.Value \
    > ${GIT_DEPLOY_KEY_LOCAL_PATH} \
    && chmod 600 ${GIT_DEPLOY_KEY_LOCAL_PATH}

# get an ssh-agent and add the key to it
ssh-agent > ~/.ssh/agent \
    && source ~/.ssh/agent \
    && ssh-add ${GIT_DEPLOY_KEY_LOCAL_PATH}

# clone the repo
mkdir -p ${INSTALL_PATH} \
    && cd ${INSTALL_PATH} \
    && ssh-keyscan github.com >> ~/.ssh/known_hosts \
    && git clone ${GIT_REPO} . \
    && git checkout ${GIT_BRANCH} \
    && chown -R ${INSTALL_USER}:${INSTALL_USER} .

## install stuff here
# cd ${INSTALL_PATH}/server
# su - ${INSTALL_USER} -c 'make install'
