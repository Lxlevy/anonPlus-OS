SHELL := /bin/bash

.PHONY: setup kernel test desktop desktop-build desktop-down desktop-logs

setup:
	./scripts/dev-setup.sh

kernel:
	./scripts/build-kernel.sh

test:
	./scripts/leak-test.sh

desktop:
	docker compose up --build -d
	@echo "anonPlus desktop: http://localhost:$${ANONPLUS_PORT:-6901} (Codespaces: open the forwarded port; username: kasm_user)"

desktop-build:
	docker compose build

desktop-down:
	docker compose down

desktop-logs:
	docker compose logs -f desktop desktop-gateway
