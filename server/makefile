SHELL=/bin/bash
.SHELLFLAGS=-lc
.ONESHELL:
.PHONY: all $(MAKECMDGOALS)

# 1.17.1
# SERVER_URL=https://launcher.mojang.com/v1/objects/a16d67e5807f57fc4e550299cf20226194497dc2/server.jar
# 1.18.1
SERVER_URL=https://launcher.mojang.com/v1/objects/125e5adf40c659fd3bce3e66e67a16bb49ecc1b9/server.jar
AWS_REGION=ap-southeast-2


WORLD_S3_PATH=$(shell aws ssm get-parameter --name /realms/outputs/world_s3_path --region ${AWS_REGION} | jq -r .Parameter.Value)
R53_ZONE_ID=$(shell aws ssm get-parameter --name /realms/outputs/route53_zone_id --region ${AWS_REGION} | jq -r .Parameter.Value)
SERVER_HOSTNAME=$(shell aws ssm get-parameter --name /realms/outputs/server_hostname --region ${AWS_REGION} | jq -r .Parameter.Value)
ASG_NAME=$(shell aws ssm get-parameter --name /realms/outputs/server_asg_name --region ${AWS_REGION} | jq -r .Parameter.Value)

PUBLIC_IP=$(shell ec2-metadata --public-ipv4 | awk '{print $$2}')

TEST_VAR=$(shell pwd)

install:
	sudo yum install awscli -y
	aws configure set default.region ${AWS_REGION}
	$(MAKE) _register_dns
	$(MAKE) _install_java
	$(MAKE) _install_minecraft

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

_register_dns:
	cat <<- EOF > _r53.json
	{"Changes": [{
		"Action": "UPSERT",
		"ResourceRecordSet": {
			"Name": "${SERVER_HOSTNAME}",
			"Type": "A",
			"TTL": 60,
			"ResourceRecords": [{"Value": "${PUBLIC_IP}"}]
		}
	}]}
	EOF
	aws route53 change-resource-record-sets \
		--hosted-zone-id ${R53_ZONE_ID} \
		--change-batch file://_r53.json

_start_autosave:
	crontab -l \
		| { cat; echo '*/10 * * * * bash -c "cd /var/realms/server && make save"'; } \
		| crontab -

start:
	$(MAKE) _download_world
	screen -dmSL mcserver make _mcserver
	$(MAKE) _start_autosave

stop:
	screen -S mcserver -p 0 -X stuff "stop^M"

save:
	screen -S mcserver -p 0 -X stuff "save-all^M"
	watch -g 'grep -m 1 "Saved the game"' screenlog.0 && $(MAKE) _upload_world

_mcserver:
	java -Xmx2048M -Xms2048M -jar server.jar nogui
	$(MAKE) _upload_world
	aws autoscaling update-auto-scaling-group \
		--auto-scaling-group-name ${ASG_NAME} \
		--max-size 0 \
		--min-size 0 \
		--desired-capacity 0
