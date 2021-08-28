SHELL=/bin/bash
.SHELLFLAGS=-lc
.ONESHELL:
.PHONY: all $(MAKECMDGOALS)

AWS_REGION=ap-southeast-2

install:
	sudo yum install awscli -y
	sudo yum install java-1.7.0-openjdk -y
	aws configure set default.region ${AWS_REGION}
