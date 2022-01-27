SHELL=/bin/sh

.PHONY: build

.DEFAULT_GOAL := help

help: 
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## build docker image locally
	@for DEBIAN_RELEASE in bullseye buster stretch ; do \
		echo "$@ $$DEBIAN_RELEASE ..."; \
		docker build --tag evaxion/debian-minion-$${DEBIAN_RELEASE}:latest --build-arg DEBIAN_RELEASE=$${DEBIAN_RELEASE} .; \
	done
	#docker tag evaxion/debian-minion-bullseye:latest evaxion/debian-minion:latest

test: ## test  salt installation
	@for DEBIAN_RELEASE in bullseye buster stretch ; do \
		echo "$@ $$DEBIAN_RELEASE ..."; \
		docker run --rm -it evaxion/debian-minion-$${DEBIAN_RELEASE}:latest /bin/bash -c "salt-call --version"; \
	done

tag-latest: ## tag latest images with a timestamp
	@for DEBIAN_RELEASE in bullseye buster stretch ; do \
		echo "$@ $$DEBIAN_RELEASE ..."; \
		docker tag evaxion/debian-minion-$${DEBIAN_RELEASE}:latest evaxion/debian-minion-$${DEBIAN_RELEASE}:`date +%s`; \
	done
	docker tag evaxion/debian-minion:latest evaxion/debian-minion:`date +%s`

console: ## run console inside image
	docker run --rm -it evaxion/debian-minion:latest /bin/bash

release: ## release new version
	act -n
