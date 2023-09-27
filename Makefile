# Parse the CI variables which are the single source of build configuration
include $(shell scripts/yaml2include.sh vars.yml)

# Local environment
VENV = .venv

# Docker
IMAGE_NAME = $(docker-registry)
LATEST_TAG = $(latest-docker-tag)
DEV_TAG = $(dev-docker-tag)
PROD_TAG = $(prod-docker-tag)
LOCK_TAG = $(lock-docker-tag)
PWD = $(shell pwd)

# Application
TEST_PATH = tests

# Deployment
PROJECT_NAME = $(project-name)
PR_PIPELINE = $(project-name)-pr
PYTHON_PACKAGE_NAME = $(python-package-name)
DEPLOY_TAG := $(shell git rev-parse HEAD)
TAG = $(DEPLOY_TAG)

# Help
BASE_PYTHON_IMAGE = $(dev-base-python-image)

# Docs
.DEFAULT_GOAL := help

#- Getting Started
## Print list of commands and exit
help:
	@docker run \
	-v $(PWD)/scripts:/scripts \
	-v $(PWD)/Makefile:/Makefile \
	--rm $(BASE_PYTHON_IMAGE) python /scripts/make_makefile_docs.py $(PROJECT_NAME)

#- Local commands

## Install the local dev environment
install:
	poetry install
	pre-commit install

## Clean the local dev environment
clean:
	rm -rf $(VENV)
	mkdir -p $(VENV)
	pre-commit uninstall

## Run python unit tests
# verbosity=0 stops pytest clogging the terminal so badly
test:
	poetry run pytest tests/ --verbosity=0

## Format all python code
format:
	poetry run isort src/ tests/
	poetry run black .

## Check the linting of all code
lint:
	poetry run flake8 .
	poetry run mypy src/
	poetry run mypy tests/

# helper
check: format lint

## Run the pre-push hooks on the changed files (which is happens when you push)
hooks:
	pre-commit run

## Run the pre-push hooks on all files in the repo
hooks-all:
	pre-commit run --all-files

#- Docker commands
#- Development

## Build the development Docker image
# podman by default builds images following the OCI format while docker uses its own.
# we pass "--format docker" to make sure we build docker images when using podman.
# when running in CI, we're using docker, and passing the --format flag causes docker to
# crash. thus we check if the $CI env var is set, as it's one of the default env vars in
# github actions.
# (https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables)
# an assumption here is that if we aren't running in CI, we're running with podman

# you can use the FLAGS arg to pass docker build args
# eg: make build FLAGS=--no-cache
# you can also use it when running commands that call build
# eg: make test-dockerised FLAGS=--no-cache
build-image:
	docker build $(if $(CI),,--format docker) $(FLAGS) \
	-t $(IMAGE_NAME):$(DEV_TAG) -f docker/Dockerfile --target=dev .

#- Debugging
## Open a bash shell inside the local dev container
open-bash: build-image
	docker run -it --rm \
	-e CI \
	-v $(PWD)/docker/venv:/opt/venv \
	-v $(PWD):/opt/project \
	$(IMAGE_NAME):$(DEV_TAG) \
	bash

#- Testing and formatting
## Run unit tests locally in a container
test-dockerised: build-image
	docker run --rm \
	-e CI \
	-v $(PWD)/docker/venv:/opt/venv \
	-v $(PWD):/opt/project \
	$(IMAGE_NAME):$(DEV_TAG) \
	test $(if $(test-args),$(test-args),$(TEST_PATH))

## Run style checks
lint-dockerised: build-image
	docker run --rm \
	-e CI \
	-v $(PWD)/docker/venv:/opt/venv \
	-v $(PWD):/opt/project \
	$(IMAGE_NAME):$(DEV_TAG) \
	lint

## Run code formatters
fmt-dockerised: build-image
	docker run --rm \
	-e CI \
	-v $(PWD)/docker/venv:/opt/venv \
	-v $(PWD):/opt/project \
	$(IMAGE_NAME):$(DEV_TAG) \
	fmt $(isort-args) $(black-args)

#- Production
## Build the production Docker image
build-prod:
	docker build \
	--build-arg AWS_ACCESS_KEY_ID \
	--build-arg AWS_SECRET_ACCESS_KEY \
	--build-arg AWS_SESSION_TOKEN \
	-e CI -t $(IMAGE_NAME):$(PROD_TAG) -t $(IMAGE_NAME):$(LATEST_TAG) -t $(IMAGE_NAME):$(DEPLOY_TAG) \
	-f docker/Dockerfile --target=prod .

## Push Docker image
push-image:
	docker push $(IMAGE_NAME):$(TAG)

#- Cleaning up
## Prune Docker containers, networks, and images
clean-docker:
	docker system prune -f
