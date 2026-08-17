# Fortress OS Architecture

## 1. Security domains

The initial design uses one kernel but separates trust domains:

```text
                        PHYSICAL NIC
                             |
                      [network namespace]
                             |
                         TOR ROUTER
                             |
                  +----------+----------+
                  | controlled veth     |
                  |                     |
             APPLICATION NS      SERVICES NS
                  |                     |
             user programs      minimal daemons
```

The application namespace has no usable route to the physical interface. Its only permitted network path is the controlled interface toward the Tor router namespace.

This preserves the "single OS" user experience while retaining a useful network isolation boundary.

It is not equivalent to a physically separate gateway or a second VM. A kernel compromise can cross namespaces.

## 2. Tor enforcement

The network policy should be fail-closed:

- application namespace -> controlled Tor path only
- direct WAN traffic -> DROP
- raw IP protocols that are not explicitly supported -> DROP
- DNS -> Tor DNS path
- Tor itself -> clearnet
- Tor bootstrap failure -> application networking becomes unusable rather than falling back to clearnet

The key property is not "applications promise to use Tor"; the kernel firewall is the enforcement point.

Whonix documents the same basic security principle: applications can be transparently routed through Tor and firewall rules can prevent direct Internet access.

## 3. Stream isolation

Each application identity should receive its own Tor SOCKS identity or equivalent isolation policy where practical.

The service manager should launch applications under an assigned network/application identity.

Do not rely on one global SOCKS port for unrelated identities.

## 4. Memory-exploitation resistance

Use layered mitigations instead of one "magic" defense:

- ASLR/PIE
- stack canaries
- W^X
- RELRO
- hardened allocator configuration
- guard pages
- seccomp for Linux user processes
- LSM policy
- privilege separation
- minimal ambient capabilities
- randomized process layouts
- kernel address-space randomization
- strict executable-memory policy
- compiler hardening
- sanitizers in CI builds
- fuzzing for security-sensitive parsers

Some of these ideas are directly inspired by OpenBSD's long-running use of W^X, ASLR, randomized memory allocation/mapping, privilege separation and kernel relinking.

No mitigation makes memory corruption impossible; the objective is to turn one bug into a much harder multi-stage attack.

## 5. System-file immutability

Use an A/B or immutable root design:

```text
BOOT
  |
signed kernel
  |
signed root hash
  |
dm-verity protected root filesystem (read-only)
  |
userspace
  |
separate writable state partition
```

`/etc`, `/usr`, `/bin`, `/sbin`, and other system paths live on the verified root.

Writable data belongs in explicit state areas.

A compromised ordinary process cannot simply edit `/usr/bin/foo` because the root block device is read-only and its blocks are checked against a cryptographic Merkle tree.

The boot chain must authenticate the root hash. Otherwise an offline attacker could replace the image and its hash together.

## 6. Updates

Updates should be atomic:

1. download a signed new image;
2. verify the publisher signature;
3. verify the full image hash;
4. write it to the inactive A/B slot;
5. verify the new slot;
6. mark it bootable;
7. reboot;
8. roll back automatically if health checks fail.

Never modify the active system image in place.

## 7. Privilege model

The system should have as little "root" as possible.

Examples:

- Tor runs as its own unprivileged account after setup.
- Network configuration is performed by a tiny privileged broker.
- GUI/session processes have no raw network administration rights.
- Hardware access is granted per device rather than globally.
- Services get only the capabilities they require.
- Sensitive operations go through small, auditable helpers.

## 8. Threat model

Strong against:

- accidental clearnet application traffic
- many DNS leaks
- many proxy-misconfiguration leaks
- ordinary user-space malware attempting to alter the immutable root
- a large class of memory-corruption exploitation
- persistence through modification of system binaries

Not guaranteed against:

- malicious/compromised firmware
- a compromised bootloader or Secure Boot trust root
- a kernel 0-day with arbitrary code execution
- DMA attacks from hostile hardware
- supply-chain compromise of trusted build/signing infrastructure
- traffic analysis by a sufficiently capable global observer
- compromised Tor infrastructure combined with correlation attacks
- user operational-security mistakes

These limits are part of the design, not footnotes.

## 9. Why one kernel instead of two VMs?

The benefit is lower complexity and lower overhead.

The trade-off is important: a second VM or physical gateway can reduce the trusted computing base and provide stronger isolation. Whonix explicitly documents physical isolation for cases where stronger separation is required.

Fortress OS therefore treats namespaces as a convenience/security layer, not as a claim of perfect isolation.

## 10. Development stages

### Stage A — networking prototype

- create namespaces
- create veth pair
- run Tor router namespace
- add nftables policy
- create automated "leak tests"

### Stage B — immutable image

- build minimal rootfs
- generate dm-verity tree
- sign root hash
- boot read-only image in QEMU
- test tamper detection

### Stage C — hardened userspace

- seccomp profiles
- Linux capabilities
- LSM policy
- sandboxed service manager
- compiler hardening

### Stage D — hardened kernel

- kernel configuration
- KASLR and hardening settings
- lockdown where supported
- hardened module policy
- measured/verified boot integration

### Stage E — adversarial testing

- network leak fuzzing
- syscall fuzzing
- filesystem mutation attempts
- crash/boot recovery tests
- kernel fuzzing
- reproducibility checks
- external security review

Only after these stages should the project be described as an OS rather than a prototype.
