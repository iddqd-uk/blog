#!/usr/bin/make
# Makefile readme (ru): <https://blog.hook.sh/nix/makefile-full-doc/>
# Makefile readme (en): <https://www.gnu.org/software/make/manual/html_node/index.html#SEC_Contents>

SHELL = /bin/bash

# Image page: <https://hub.docker.com/r/klakegg/hugo>
HUGO_IMAGE := klakegg/hugo:0.81.0-alpine
RUN_ARGS = --rm -v "$(shell pwd):/src:rw" --user "$(shell id -u):$(shell id -g)"

.PHONY : help pull start new-post test clean
.DEFAULT_GOAL : help

help: ## Show this help
	@printf "\033[33m%s:\033[0m\n" 'Available commands'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[32m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

pull: ## Pull all required Docker images
	docker pull "$(HUGO_IMAGE)"

start: ## Start local hugo live server
	docker run $(RUN_ARGS) -p 1313:1313 -ti "$(HUGO_IMAGE)" server \
		--watch \
		--logFile /dev/stdout \
		--environment development \
		--baseURL 'http://127.0.0.1:1313/' \
		--port 1313 \
		--bind 0.0.0.0

.ONESHELL:
new-post: pull ## Make new post (post name must be passed through ENV value)
	@read -p "Enter new post name (like 'category/my-first-post', without '.md' extension): " NEW_POST_NAME
	docker run $(RUN_ARGS) "$(HUGO_IMAGE)" new "$$NEW_POST_NAME.md"
	-gedit "./content/$$NEW_POST_NAME.md" &

test: ## Execute tests
	docker run $(RUN_ARGS) -w "/src" avtodev/markdown-lint:v1 '**/*.md'

clean: ## Make some clean
	-rm -Rf ./public

