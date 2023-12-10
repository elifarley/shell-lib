.PHONY: all venv setup test debug dumpreq docker run api loadtest help
.ONESHELL:
SHELL := scripts/timed-shell.sh
# .SHELLFLAGS := -e -o pipefail -c # Make bash fail and report the 1st error in ;-separated lists or pipes.

IMAGE_NAME?=sam-sbom-uploader
export IMAGE_NAME _
IMAGE_BUILDER?=docker
export IMAGE_BUILDER _
LOADTEST_TYPE?=default
export LOADTEST_TYPE _

# Default action
all: test run
	@echo "Running tests and starting the Docker container..."

venv:
	@test -d .venv && exit
	read -p "How to invoke Python 3.12? (python3.12): " python_cmd
	python_cmd="$${python_cmd:-python3.12}"
	$$python_cmd --version || exit
	$$python_cmd -m pip install virtualenv && $$python_cmd -m virtualenv .venv

setup: venv
	. .venv/bin/activate \
	&& pip install -r app/requirements.txt python-dotenv pyyaml 'pytest~=7.4' requests_mock \
	| grep -v 'already satisfied'
	echo "Now, activate the Python virtual env:"
	echo ". .venv/bin/activate"

test: api
	@echo "Running pytest..."
	python --version
	pytest --version
	pytest -q tests

# Run the Flask application in debug mode
debug:
	@echo "Running app in debug mode..."
	./run.py

dumpreq:
	@echo "Dumping requests to out/requests.txt"
	mkdir -p out; nc -l 5000 | tee out/requests.txt

docker:
	@echo "Building Docker image '$(IMAGE_NAME)'"
	$(IMAGE_BUILDER) build -t $(IMAGE_NAME) . --progress=plain

run: docker
	@echo "Running Docker container..."
	docker run -p 5000:5000 \
	-m 100m --memory-reservation=70m \
	--cpus 0.1 --cpu-shares=2 \
	-e ENV_VAR_1="$(ENV_VAR_1)" \
	$(IMAGE_NAME)

loadtest:
	@echo "Starting load test..."
	hey -t 60 -n 200 -c 5 -m POST -D tests/request-$(LOADTEST_TYPE).txt -T 'multipart/form-data; boundary=#b.o.u.n.d.a.r.y#' \
    http://localhost:5000/bom

api:
	@echo "Exporting the OpenAPI Specification..."
	flask --app app:flask_app openapi -f yaml > api/openapi.yaml
	cat api/openapi.yaml
	printf 'Exported lines: '; wc -l api/openapi.yaml

define HELP_MESSAGE
Usage:
  make [target]

Targets:
  all      Run tests and start Docker container (default)
  venv     Installs a Python virtual env in .venv
  setup    Installs Python requirements in the current virtual env
  test     Run pytest to execute all tests
  debug    Run Flask application in debug mode
  dumpreq  Dump requests to out/requests.txt
  docker   Build Docker image named '$(IMAGE_NAME)'
  run      Run the service via a Docker container
  loadtest Show loadtest summary
  api      Export the OpenAPI Specification to api/openapi.yaml
  help     Display this help message
endef
export HELP_MESSAGE

help: SHELL:=/bin/sh
help:
	@echo "$$HELP_MESSAGE"
