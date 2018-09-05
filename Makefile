#SHELL = /bin/bash

app_name := bitwarden-cli-docker
app_version := $(shell npm view @bitwarden/cli "dist-tags".latest)
dockerfile_version="$(shell grep -oP '(?<=bitwarden/cli@)[0-9.]+' Dockerfile)"
actual_version="$(shell docker run --rm $(app_name):$(app_version) --version)"

docker_name := fbartels/$(app_name)
#$(app_version)

docker_login=`cat ~/.docker-account-user`
docker_pwd=`cat ~/.docker-account-pwd`

all: update test run

release: all tag publish

update:
	@echo "Checking if Dockerfile needs updating"
	if [ "${app_version}" != "${dockerfile_version}" ]; then \
		sed -i "s|^RUN npm.*|RUN npm install -g @bitwarden/cli@${app_version}|" Dockerfile; \
		git add Dockerfile; \
		git commit -m "ci: bump to ${app_version}"; \
		git push origin master; \
	fi
build:
	@echo "Building Docker image"
	docker build -t $(app_name):${app_version} .

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
	$(app_name):${app_version} --help
	echo ${actual_version} > $(HOME)/.config/bitwarden/version

repo-login:
	docker login -u $(docker_login) -p $(docker_pwd)

# Docker tagging
tag: tag-latest tag-version

tag-latest:
	@echo 'create tag latest'
	docker tag $(app_name) $(docker_name):latest

tag-version:
	@echo 'create tag $(app_version)'
	docker tag $(app_name) $(docker_name):$(app_version)

# Docker publish
publish: repo-login publish-latest publish-version

publish-latest: tag-latest
	@echo 'publish latest to $(docker_name)'
	docker push $(docker_name):latest

publish-version: tag-version
	@echo 'publish $(app_version) to $(docker_name)'
	docker push $(docker_name):$(app_version)
