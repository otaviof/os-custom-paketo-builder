# fully qualifiyed image name components
IMAGE_BASE ?= ghcr.io
IMAGE_REPO ?= otaviof
IMAGE_NAME ?= os-custom-paketo-builder
IMAGE_TAG ?= latest

FQIN = $(IMAGE_BASE)/$(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

default: build

.PHONY: build
build:
	docker build --tag=$(FQIN) .

.PHONY: push
push:
	docker push $(FQIN)
