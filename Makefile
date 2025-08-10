DOCKER_IMAGE = python-agent-runner
DOCKER_TAG = 3.10


.PHONY: build deploy clean test

all: clean build deploy

build:
	docker build --build-arg USERNAME=$(shell whoami) -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker save -o $(DOCKER_IMAGE).tar $(DOCKER_IMAGE):$(DOCKER_TAG)
# 	ctr -n k8s.io images import $(DOCKER_IMAGE).tar

deploy:
	docker load -i $(DOCKER_IMAGE).tar

clean:
	$(RM)