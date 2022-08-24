SEVERITIES = HIGH,CRITICAL

ifeq ($(ARCH),)
ARCH=$(shell go env GOARCH)
endif

BUILD_META=-build$(shell date +%Y%m%d)
ORG ?= rancher
PKG ?= go.etcd.io/etcd
SRC ?= github.com/k3s-io/etcd
TAG ?= v3.5.0-k3s2$(BUILD_META)
CREATED ?= $(shell date --iso-8601=s -u)
REF ?= $(shell git symbolic-ref HEAD)

ifneq ($(DRONE_TAG),)
TAG := $(DRONE_TAG)
endif

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG needs to end with build metadata: $(BUILD_META))
endif

.PHONY: image-build
image-build:
	docker build \
		--build-arg PKG=$(PKG) \
		--build-arg SRC=$(SRC) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
		--build-arg ARCH=$(ARCH) \
		--build-arg ETCD_UNSUPPORTED_ARCH=$(ETCD_UNSUPPORTED_ARCH) \
		--label "org.opencontainers.image.url=https://github.com/brooksn/image-build-etcd" \
		--label "org.opencontainers.image.created=$(CREATED)" \
		--label "org.opencontainers.image.authors=brooksn" \
		--label "org.opencontainers.image.ref.name=$(REF)" \
		--tag $(ORG)/hardened-etcd:$(TAG) \
		--tag $(ORG)/hardened-etcd:$(TAG)-$(ARCH) \
	.

.PHONY: image-push
image-push:
	docker push $(ORG)/hardened-etcd:$(TAG)-$(ARCH)

.PHONY: image-manifest
image-manifest:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-etcd:$(TAG) \
		$(ORG)/hardened-etcd:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-etcd:$(TAG)

.PHONY: image-scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-etcd:$(TAG)
