

.PHONY: docker-build docker-shell print-build-args \
	default build \
	print-docker-hub-image

SHELL=bash

default:
	echo pass

######
# Android build-y stuff

build:
	export ANDROID_SDK_ROOT=$HOME/Android/Sdk; \
	./gradlew build

######
# docker stuff

IMAGE=phlummox/gitpod-android-studio
VERSION=0.1.1

GIT_REF = $(shell git rev-parse HEAD)
GIT_COMMIT_DATE=$(shell git show -s --format=%cI $(GIT_REF))
GIT_TAGS= $(shell git tag -l)

print-build-args:
	@printf '%s %s\n' '--build-arg GIT_REF=$(GIT_REF)' \
		'--build-arg GIT_COMMIT_DATE=$(GIT_COMMIT_DATE)' \
		'--build-arg VERSION=$(VERSION)'

print-docker-hub-image:
	@printf '%s' "$(IMAGE)"

print-version:
	@printf '%s' "$(VERSION)"

#docker-build:
#	set -x; \
#	build_args="$$(make --no-print-directory --quiet print-build-args)"; \
#	docker build --pull $$build_args \
#		-f .gitpod.Dockerfile $(TAGS_TO_ADD) $(TAGS_IN) -t $(IMAGE):$(VERSION) .

docker-build:
	docker build \
		-f Dockerfile $(TAGS_TO_ADD) $(TAGS_IN) -t $(IMAGE):$(VERSION) .



docker-shell:
	docker -D run -e DISPLAY -it --rm  --net=host  \
		-v $$PWD:/work \
		$(MOUNT)                  \
		--env QT_X11_NO_MITSHM=1 \
		$(IMAGE):$(VERSION) bash

