PACKAGE = bash
ORG = amylum

BUILD_DIR = /tmp/$(PACKAGE)-build
RELEASE_DIR = /tmp/$(PACKAGE)-release
RELEASE_FILE = /tmp/$(PACKAGE).tar.gz
PATH_FLAGS = --sbindir=/usr/bin
CFLAGS = -static -static-libgcc -Wl,-static -lc

PACKAGE_VERSION = $$(git --git-dir=upstream/.git log HEAD...HEAD~ | tail -1 | sed 's/Bash-\([0-9.]*\) patch \([0-9]*\)/\1p\2/')
PATCH_VERSION = $$(cat version)
VERSION = $(PACKAGE_VERSION)-$(PATCH_VERSION)

.PHONY : default submodule manual container build version push local

default: submodule container

submodule:
	git submodule update --init

manual: submodule
	./meta/launch /bin/bash || true

container:
	./meta/launch

build: submodule
	rm -rf $(BUILD_DIR)
	cp -R upstream $(BUILD_DIR)
	cd $(BUILD_DIR) && ./autogen.sh
	cd $(BUILD_DIR) && CC=musl-gcc CFLAGS='$(CFLAGS)' ./configure $(PATH_FLAGS)
	cd $(BUILD_DIR) && make install
	mkdir -p $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)
	cp $(BUILD_DIR)/COPYING $(RELEASE_DIR)/usr/share/licenses/$(PACKAGE)/LICENSE
	cd $(RELEASE_DIR) && tar -czvf $(RELEASE_FILE) *

version:
	@echo $$(($(PATCH_VERSION) + 1)) > version

push: version
	git commit -am "$(VERSION)"
	ssh -oStrictHostKeyChecking=no git@github.com &>/dev/null || true
	git tag -f "$(VERSION)"
	git push --tags origin master
	@sleep 3
	targit -a .github -c -f $(ORG)/$(PACKAGE) $(VERSION) $(RELEASE_FILE)

local: build push

