FROM kasmweb/ubuntu-jammy-desktop:1.17.0

USER root

# Keep the base KasmVNC session and add a small, useful desktop toolkit.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        htop \
        net-tools \
        xterm \
    && rm -rf /var/lib/apt/lists/*

RUN printf '%s\n' \
    'anonPlus OS desktop' \
    'Browser workspace for the anonPlus OS research prototype.' \
    > /etc/anonplus-desktop.txt

USER kasm-user
