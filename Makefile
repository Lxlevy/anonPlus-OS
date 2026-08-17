SHELL := /bin/bash

.PHONY: setup kernel test

setup:
	./scripts/dev-setup.sh

kernel:
	./scripts/build-kernel.sh

test:
	./scripts/leak-test.sh
