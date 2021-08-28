SHELL=/bin/bash
.SHELLFLAGS=-lc
.ONESHELL:
.PHONY: all $(MAKECMDGOALS)

# 1.17.1
SERVER_URL=https://launcher.mojang.com/v1/objects/a16d67e5807f57fc4e550299cf20226194497dc2/server.jar
AWS_REGION=ap-southeast-2

WORLD_S3_SSM_PATH=/realms/outputs/world_s3_path
WORLD_S3_PATH=$(shell aws ssm get-parameter --name ${WORLD_S3_SSM_PATH} --region ${AWS_REGION} | jq -r .Parameter.Value)

install:
	sudo yum install awscli -y
	aws configure set default.region ${AWS_REGION}
	$(MAKE) _install_java
#	$(MAKE) _install_minecraft

_install_java:
	sudo rpm --import https://yum.corretto.aws/corretto.key
	sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
	sudo yum install -y java-16-amazon-corretto-devel

_install_minecraft:
	curl ${SERVER_URL} -o server.jar
	echo "eula=true" > eula.txt

_download_world:
	rm -rf *
	aws s3 cp ${WORLD_S3_PATH} .
	tar -xzvf server.tar.gz
	git checkout -- .

_upload_world:
	rm -f server.tar.gz
	tar -czvf server.tar.gz --exclude=screenlog.* --exclude=logs *
	aws s3 cp server.tar.gz ${WORLD_S3_PATH}

start:
	$(MAKE) _download_world
	screen -dmSL mcserver make _mcserver

stop:
	screen -S mcserver -p 0 -X stuff "stop^M"

_mcserver:
	java -Xmx1024M -Xms1024M -jar server.jar nogui
	$(MAKE) _upload_world

test:
	A=`echo foo`
	echo $${A}

