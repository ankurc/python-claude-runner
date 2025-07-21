DOCKER_IMAGE = python-claude-runner
DOCKER_TAG = 3.10

# Detect OS for cross-platform compatibility
ifeq ($(OS),Windows_NT)
    RM = if exist "$(DOCKER_IMAGE).tar" del /f /q "$(DOCKER_IMAGE).tar"
    USER_ID = 1000
    GROUP_ID = 1000
else
    RM = [ -f "$(DOCKER_IMAGE).tar" ] && rm -f "$(DOCKER_IMAGE).tar" || true
    USER_ID = $(shell id -u)
    GROUP_ID = $(shell id -g)
endif

.PHONY: build deploy clean test

all: clean build deploy

build:
	docker build --build-arg USER_UID=$(USER_ID) --build-arg USER_GID=$(GROUP_ID) -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker save -o $(DOCKER_IMAGE).tar $(DOCKER_IMAGE):$(DOCKER_TAG)
# 	ctr -n k8s.io images import $(DOCKER_IMAGE).tar

deploy:
	docker load -i $(DOCKER_IMAGE).tar

clean:
	$(RM)