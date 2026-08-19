# Contributing to anonPlus OS

anonPlus OS is a security-focused research prototype. Contributions should
favor explicit security boundaries, reproducible builds, small changes, and
honest documentation of what is implemented versus planned. Or just don't contribute, I dont know.

## Before you start

Read:

- `README.md` for project status and development limitations
- `docs/architecture.md` for the intended trust and network boundaries
- `config/security-baseline.txt` for the security requirements

The project is not production security software. Do not use the desktop or
networking prototype for anonymity-sensitive activity.

## Development environment

The recommended environment is Ubuntu 24.04 or GitHub Codespaces. Install the
project dependencies with:

```sh
make setup
```

The setup installs compiler tools, Linux networking tools, Tor, nftables,
QEMU, debootstrap, dm-verity tooling, and related build dependencies.

## Common workflows

Validate shell scripts and the kernel hardening contract:

```sh
bash -n scripts/*.sh
make hardening-check
```

Start the host namespace networking prototype:

```sh
make network-up
```

This requires root network administration privileges. It creates:

- `anonplus-tor`: the Tor router namespace
- `anonplus-app`: the application namespace
- a controlled veth path between them
- nftables rules that default to drop
- transparent TCP and DNS routing through Tor

Stop and clean up the prototype with:

```sh
make network-down
```

Run the executable networking tests with:

```sh
make test
```

The test checks namespace topology, default routes, nftables rules, Tor
identity, DNS resolution, and loss of connectivity when Tor stops. `network-up`
refuses to report success until Tor reaches 100 percent bootstrap. Some
Codespaces environments do not permit the nested router namespace to forward
outbound TCP; in that case, a failed bootstrap is expected and is fail-closed.

Build the immutable root image with an explicit signing key:

```sh
SIGNING_KEY=/absolute/path/to/development-key.pem make rootfs
```

Never commit signing keys, generated images, build directories, or local
`.env` files. Production signing keys must be held outside the repository.

Run the QEMU smoke test after a kernel image and root image exist:

```sh
make qemu-test
```

The test intentionally fails when required boot artifacts or the
`anonplus-boot-ok` health marker are missing.

The browser desktop is a separate development UX layer:

```sh
cp .env.example .env
# Set a private password in .env.
make desktop
```

Use `make desktop-down` to stop it. Do not expose the desktop directly to the
public internet without reviewed authentication, TLS, and network controls.

## Making changes

Keep changes scoped to the behavior being changed. Prefer existing shell,
Makefile, Linux namespace, nftables, Tor, dm-verity, and QEMU patterns over
introducing new abstractions.

For security-sensitive changes:

1. State the security property being added or preserved.
2. Add a failing test or a focused validation when practical.
3. Test both the allowed path and the denied path.
4. Document environment limitations and assumptions.
5. Avoid weakening a default-deny rule to make a local test pass.

Do not claim that a feature is enforced merely because it appears in the
architecture document or security baseline. Update the README milestone status
when implementation state changes.

## Pull requests

Pull requests should include:

- a short explanation of the behavior change
- the commands used for validation
- any tests that could not run and why
- security or threat-model implications
- documentation updates for new commands or changed guarantees

Do not include credentials, private keys, generated artifacts, personal
`.env` files, or unrelated formatting changes.
