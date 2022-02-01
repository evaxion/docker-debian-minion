SHELL=/bin/sh

.PHONY: build build test tag-latest console workflow

.DEFAULT_GOAL := help

DEBIAN_RELEASES = bullseye buster stretch jessie
help: 
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## build docker image locally
	@for DEBIAN_RELEASE in $(DEBIAN_RELEASES); do \
		echo "$@ $$DEBIAN_RELEASE ..."; \
		docker build --tag evaxion/debian-minion-$${DEBIAN_RELEASE}:latest --build-arg DEBIAN_RELEASE=$${DEBIAN_RELEASE} .; \
	done
	#docker tag evaxion/debian-minion-bullseye:latest evaxion/debian-minion:latest

test: ## test  salt installation
	@for DEBIAN_RELEASE in $(DEBIAN_RELEASES) ; do \
		echo "$@ $$DEBIAN_RELEASE ..."; \
		docker run --rm -it evaxion/debian-minion-$${DEBIAN_RELEASE}:latest /bin/bash -c "salt-call --local test.version"; \
	done

tag-latest: ## tag latest images with a timestamp
	@for DEBIAN_RELEASE in $(DEBIAN_RELEASES) ; do \
		echo "$@ $$DEBIAN_RELEASE ..."; \
		docker tag evaxion/debian-minion-$${DEBIAN_RELEASE}:latest evaxion/debian-minion-$${DEBIAN_RELEASE}:`date +%s`; \
	done
	@docker tag evaxion/debian-minion:latest evaxion/debian-minion:`date +%s`

console: ## run console inside image
	@docker run --rm -it evaxion/debian-minion:latest /bin/bash

workflow: ## run github workflow locally
	@./scripts/test-workflow.sh
