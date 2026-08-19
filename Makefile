SHELL := /bin/bash

.PHONY: setup kernel rootfs hardening-check qemu-test network-up network-down test desktop desktop-build desktop-down desktop-logs

setup:
	./scripts/dev-setup.sh

kernel:
	./scripts/build-kernel.sh

rootfs:
	sudo ./scripts/build-immutable-root.sh

hardening-check:
	./scripts/check-kernel-config.sh

qemu-test:
	./scripts/qemu-smoke.sh

network-up:
	sudo ./scripts/network-up.sh

network-down:
	sudo ./scripts/network-down.sh

test:
	sudo ./scripts/leak-test.sh

desktop:
	docker compose up --build -d
	@echo "anonPlus desktop: http://localhost:$${ANONPLUS_PORT:-6901} (Codespaces: open the forwarded port; username: kasm_user)"

desktop-build:
	docker compose build

desktop-down:
	docker compose down

desktop-logs:
	docker compose logs -f desktop desktop-gateway
