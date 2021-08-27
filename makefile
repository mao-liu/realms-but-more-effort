CONDA_ENV = $(shell head -n1 environment.yaml | sed 's/name: //')

SHELL=/bin/bash
.SHELLFLAGS=-lc
.ONESHELL:
.PHONY: all $(MAKECMDGOALS)

help:	## # Show this help
	@echo "${CONDA_ENV}"
	@echo ""
	@echo "Usage:"
	@sed -ne '/@sed/!s/:.*## / /p' $(MAKEFILE_LIST) | sed 's/^/  make /' | column -s "#" -t

env-init:			## # Create conda environment
	conda env create -f environment.yaml --force
	conda activate ${CONDA_ENV}
	$(MAKE) _auth_setup

env-clean:			## # Remove conda environment
	conda env remove -n ${CONDA_ENV}

env-update:			## # Update conda environment
	conda activate ${CONDA_ENV}
	conda env update --file environment.yaml --prune

check-env:
ifndef ENV
	$(error ENV is undefined)
endif

auth:		## ENV=<env> # Get an MFA session with AWS
	@conda activate ${CONDA_ENV}
	bash scripts/aws_credential_auth.sh

_auth_setup:			## # setup AWS CLI configuration
	conda activate ${CONDA_ENV}
	bash scripts/aws_credential_init.sh
