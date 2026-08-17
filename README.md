# Fortress OS

A research prototype for a single-OS privacy/security platform combining:

- Tor-enforced networking with a fail-closed kill switch
- application/network isolation without requiring two guest VMs
- OpenBSD-inspired exploit mitigations
- cryptographically verified, read-only system files
- separate mutable state
- reproducible development in GitHub Codespaces

## Important security claim

This project does **not** claim that IP discovery is mathematically impossible or that zero-days are impossible.

The goal is stronger and more defensible:

1. ordinary applications have no direct clearnet route;
2. non-Tor network traffic fails closed;
3. system partitions are read-only at runtime;
4. system integrity is checked cryptographically;
5. memory-safety and control-flow attacks face multiple independent mitigations;
6. privileged components are minimized and isolated.

A successful kernel/firmware/boot-chain compromise can defeat an OS-level design, so the final security model must explicitly include hardware and physical attackers.

## Development model

GitHub Codespaces is used for source development, reproducible builds, unit tests, static analysis, and QEMU image creation.

The final security validation must happen on a real test machine with the intended boot chain, because a Codespace is itself a VM and cannot establish the security properties of the eventual physical platform.

## Architecture

See `docs/architecture.md`.

## First milestone

The first milestone is intentionally small:

- Linux kernel
- minimal userspace
- Tor daemon in a dedicated network namespace
- application namespace with no physical NIC
- nftables fail-closed policy
- DNS forced through Tor
- read-only verified root filesystem
- writable `/var` and `/home` on separate state storage
- QEMU integration tests

## Status

Research prototype. Not production security software.
