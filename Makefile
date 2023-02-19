# fully qualifiyed image name components
IMAGE_REGISTRY ?= ghcr.io
IMAGE_NAME ?= otaviof/os-custom-paketo-builder
IMAGE_TAG ?= latest

FQIN = $(IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

default: build

.PHONY: build
build:
	docker build --tag=$(FQIN) .

.PHONY: push
push:
	docker push $(FQIN)
