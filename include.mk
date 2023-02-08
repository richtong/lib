#
##
## Base commands
## -------------
#
TAG ?= v1
# https://www.gnu.org/software/make/manual/make.html#Flavors
# Use simple expansion for most and not ?= since default is /bin/bash
# which is bash v3 for MacOS
SHELL := /usr/bin/env bash
GIT_ORG ?= richtong
SUBMODULE_HOME ?= "$(HOME)/ws/git/src"
NEW_REPO ?=
name ?= $$(basename "$(PWD)")
# if you have include.python installed then it uses the environment but by
# default we assume we are using the raw environment
RUN ?=
FORCE ?= false

.DEFAULT_GOAL := help
.PHONY: help
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html does not
# work because we use an include file
# https://swcarpentry.github.io/make-novice/08-self-doc/ is simpler just need
# and it dumpes them out relies on the variable MAKEFILE_LIST which is a list of
# all files note we do not just use $< because this is an include.mk file
## help: available commands (the default)
help: $(MAKEFILE_LIST)
	@sed -n 's/^##//p' $(MAKEFILE_LIST)

# https://stackoverflow.com/questions/4728810/how-to-ensure-makefile-variable-is-set-as-a-prerequisite/7367903#7367903
# Clever trick using replacement where the % means match all targets that look
# like this and ${*} means provide me with the targets
# So a dependency on guard-PIPENV_ACTIVE would make sure you are in pipenv
.PHONY: unset-%
unset-%:
	@if [[ -n "${${*}}" ]]; then \
		echo "Environment variable $* must not be set for this Make rule to run"; \
		exit 1; \
	fi

.PHONY: set-%
set-%:
	@if [[ -z "${${*}}" ]]; then \
		echo "Environment variable $* must set for this Make rule to run"; \
		exit 1; \
	fi

## These are required tags from checkmate stubs are here you should overwrite
#.PHONY: test
#test:
#    @echo "test stub"

## tag: pushes a new tag up while delete old to force the action
.PHONY: tag
tag:
	git tag -d "$(TAG)"; \
	git push origin :"$(TAG)" ; \
	git tag -a "$(TAG)" -m "$(COMMENT)" && \
	git push origin "$(TAG)"

## mkdocs: Generate a mkdocs web server at http://localhost:8000
.PHONY: mkdocs
mkdocs:
	mkdocs serve & \
	sleep 2 && \
    open http://localhost:8000


## mkdocs-stop: Kill the mkdocs server at http://localhost:8000
.PHONY: mkdocs-stop
mkdocs-stop:
	pkill mkdocs


## doctoc: generate toc for markdowns at the top level (deprecated)
.PHONY: doctoc
doctoc:
	doctoc *.md

## install-repo: installation
# set these to the destination FILE and the source TEMPLATE if the file does
# not exist are you are using FORCE to overwrite
.PHONY: install-repo
FILE ?=     .gitattributes \
			.gitignore \
			.pre-commit-config.yaml \
			.github/workflows/workflow.full.gha.yaml \
			.tool-versions \
			.envrc \
			pyproject.toml \
			runtime.txt \
			netlify.toml \
			mkdocs.yml

TEMPLATE ?= gitattributes.base \
			gitignore.base \
			pre-commit-config.full.yaml \
			workflow.full.gha.yaml \
			tool-versions.full \
			envrc.full \
			pyproject.full.toml \
			runtime.full.txt \
			netlify.full.toml \
			mkdocs.base.yml

install-repo:
	FILE=( $(FILE) ) && \
	TEMPLATE=( $(TEMPLATE) ) && \
	for (( i=0; i<$${#FILE[@]}; i++ )); do \
		if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/$${FILE[i]} && \
			! -e $${TEMPLATE[i]} ]]; then \
				cp "$(WS_DIR)/git/src/lib/$${FILE[i]}" $${TEMPLATE[i]}; \
	    else \
			echo "skipped $$i $${FILE[i]} $${TEMPLATE[i]}"; \
		fi; \
	done

## install-repo-old: deprecated Install repo basics like gitattributes, gitignore pre-commit, GitHub Actions and prereq tfrom $WS_DIR use $FORCE it you want to overwrite
.PHONY: install-repo-old
install-repo-old:
	for PREREQ in markdownlint-cli shellcheck shfmt hadolint git-lfs; do \
		if ! command -v "$$PREREQ" >/dev/null; then brew install "$$PREREQ"; fi ;\
	done && \
	for PREREQ_PIP in pynvim; do \
	    pip install "$$PREREQ_PIP"; \
	done && \
	if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/gitattributes.base && \
		! -e .gitattributes ]]; then \
			cp "$(WS_DIR)/git/src/lib/gitattributes.base" .gitattributes; \
	fi && \
	if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/gitignore.base && \
		! -e .gitignore ]]; then \
			cp "$(WS_DIR)/git/src/lib/gitignore.base" .gitignore; \
	fi && \
	if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/pre-commit-config.full.yaml && \
		! -e .pre-commit-config.yaml ]]; then \
			cp "$(WS_DIR)/git/src/lib/pre-commit-config.full.yaml" .pre-commit-config.yaml; \
	fi && \
	if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/workflow.full.gha.yaml && \
		! -e .github/workflows/workflow.full.gha.yaml ]]; then \
			mkdir -p .github/workflows; \
			cp "$(WS_DIR)/git/src/lib/workflow.full.gha.yaml" .github/workflows; \
	fi && \
	if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/tool-versions.full && \
		! -e .tool-versions ]]; then \
			cp "$(WS_DIR)/git/src/lib/tool-versions.full" .tool-versions; \
	fi && \
	if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/envrc.full && \
		! -e .envrc ]]; then \
			cp "$(WS_DIR)/git/src/lib/envrc.full" .envrc; \
	fi &&
	if $(FORCE) || [[ -e $(WS_DIR)/git/src/lib/pyproject.full.toml && \
		! -e pyproject.toml ]]; then \
			cp "$(WS_DIR)/git/src/lib/pyproject.full.toml" pyproject.toml; \
	fi

## pre-commit: Run pre-commit hooks and install if not there with update
.PHONY: pre-commit
pre-commit: install-pre-commit
	@echo this does not work on WSL so you need to run pre-commit install manually
	if [[ ! -e .pre-commit-config.yaml ]]; then \
		echo "no .pre-commit-config.yaml found copy from ./lib"; \
	else \
		$(RUN) pre-commit run --all-files || true \
	; fi

## install-pre-commit: Install precommit (get prebuilt .pre-commit-config.yaml from @richtong/lib)
.PHONY: install-pre-commit
install-pre-commit: install-repo
	if [[ -e .pre-commit-config.yaml ]]; then \
		$(RUN) pre-commit install || true && \
		pre-commit install --hook-type commit-msg \
	; fi

## pre-commit-update: Bump all pre-commit versions
.PHONY: pre-commit-update
pre-commit-update:
		$(RUN) pre-commit autoupdate || true

## act: Run Github actions as docker job on local machine only works as amd64
# https://github.com/nektos/act/issues/285
# --reuse make the cache work locally
.PHONY: act
act:
	act --reuse --container-architecture linux/amd64

## git-lfs: installs git lfs
.PHONY: git-lfs
git-lfs:
	$(RUN) brew install git-lfs
	$(RUN) git lfs install
	$(RUN) git add --all
	$(RUN) git commit -av
	# this will fail if you are not already committed
	$(RUN) git lfs pull

## install-src: creates repo and submodules ./{bin,lib,docker}
.PHONY: install-repo
install-src: git-lfs install-repo
	$(RUN) for repo in bin lib docker; do git submodule add git@github.com:$(GIT_ORG)/$$repo; done
	$(RUN) git submodule update --init --recursive --remote

## install-submodule: installs a new submodule $(GIT_ORG)/$(NEW_REPO)
.PHONY: install-submodule
install-submodule:
ifeq ($(NEW_REPO),)
	@echo "create with make git NEW_REPO=_name_"
else
	gh repo create git@github.com:$(GIT_ORG)/$(NEW_REPO)
	cd $(SUBMODULE_HOME)
	git submodule add git@github.com:$(GIT_ORG)/$(NEW_REPO)
	cd $(NEW_REPO)
	git init
	cat "## $(ORG) $(name) repo" >> README.md
	git commit -m "README.md first commit"
	git branch -M main
	git push -u origin main
endif

## direnv: creates a new environemnt with direnv and asdf
.PHONY: direnv
direnv:
	touch .envrc
	direnv allow .envrc

## install-brew: install brew packages
# quote needed in case BREW is not set
.PHONY: install-brew
install-brew:
	if [[ -n "$(BREW)" ]]; then \
		brew install $(BREW) \
	; fi

LIB_SOURCE ?= ../../lib
LIB_FILES ?= include.python.mk include.mk
## lib-sync: sync from $(LIB_FILES) from $(LIB) for independent PIP packages
.PHONY: lib-sync
lib-sync:
	for f in $(LIB_FILES); do \
		if [[ -e $(LIB_SOURCE)/$$f ]]; then \
			rsync -av "$(LIB_SOURCE)/$$f" "$$f" \
		; fi \
	; done
