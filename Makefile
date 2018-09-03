#SHELL = /bin/bash

app_name := bitwarden-cli-docker
app_version := $(shell npm view @bitwarden/cli "dist-tags".latest)
dockerfile_version="$(shell grep -oP '(?<=bitwarden/cli@)[0-9.]+' Dockerfile)"
actual_version="$(shell docker run --rm $(docker_name):$(app_version) --version)"

docker_name := fbartels/$(app_name)
#$(app_version)

all: update test run

update:
	@echo "Checking if Dockerfile needs updating"
	if [ "${app_version}" != "${dockerfile_version}" ]; then \
		sed -i "s|\(install -g @bitwarden/cli@\)[0-9\.]\+$|\1${app_version}|" Dockerfile; \
		git add Dockerfile; \
		git commit -m "ci: bump to ${app_version}"; \
		git push origin master; \
	fi
build:
	@echo "Building Docker image"
	docker build -t $(docker_name):$(app_version) .

test: build
	@echo "Checking version in Docker image"
	if [ "${dockerfile_version}" != "${actual_version}" ]; then \
		@echo "test failed"; exit 1; \
	fi

run:
	mkdir -p $(HOME)/.config/bitwarden
	# setting custom server: bw config server https://bitwarden.domain.com
	docker run -it --rm \
	-v $(HOME)/.config/bitwarden:"/root/.config/Bitwarden CLI" \
	$(docker_name):$(app_version) --help
