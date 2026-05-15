FROM node:22.13.0-bookworm AS builder

ARG UMBREL_VERSION=1.7.3

WORKDIR /src
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${UMBREL_VERSION}" https://github.com/getumbrel/umbrel /src

# Install umbreld (including devDeps) before UI build: Vite resolves shared TS that pulls in
# packages/umbreld/tsconfig.json, which extends @tsconfig/node22 (a umbreld devDependency).
WORKDIR /src/packages/umbreld
RUN npm ci || npm install

WORKDIR /src/packages/ui
RUN npm ci || npm install
RUN npm run build

# Runtime umbreld needs production deps only (smaller COPY into final image).
WORKDIR /src/packages/umbreld
RUN rm -rf node_modules && (npm ci --omit=dev || npm install --omit=dev)


FROM tao9317/tao-umbrel:latest AS final

ARG UMBREL_VERSION=1.7.3
# Matches getumbrel/umbrel 1.7.3 packages/os/umbrelos.Dockerfile (bump KOPIA_* when upgrading UMBREL_VERSION).
ARG TARGETARCH=amd64
ARG KOPIA_VERSION=0.19.0
ARG KOPIA_SHA256_amd64=c07843822c82ec752e5ee749774a18820b858215aabd7da448ce665b9b9107aa
ARG KOPIA_SHA256_arm64=632db9d72f2116f1758350bf7c20aa57c22c220480aaccb5f839e75669210ed9

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dbus \
    udev \
    udisks2 \
    samba \
    smbclient \
    cifs-utils \
    usbutils \
    util-linux \
    e2fsprogs \
    ntfs-3g \
    exfatprogs \
    lsof \
    fuse3 \
    bindfs \
  && rm -rf /var/lib/apt/lists/*

# Kopia + FUSE per umbrelOS (umbreld execa('kopia', ...) and kopia mount for restore).
RUN KOPIA_ARCH="$([ "${TARGETARCH}" = "arm64" ] && echo "arm64" || echo "x64")" && \
    KOPIA_SHA256="$(eval echo \$KOPIA_SHA256_${TARGETARCH})" && \
    curl -fsSL "https://github.com/kopia/kopia/releases/download/v${KOPIA_VERSION}/kopia-${KOPIA_VERSION}-linux-${KOPIA_ARCH}.tar.gz" -o /tmp/kopia.tar.gz && \
    echo "${KOPIA_SHA256}  /tmp/kopia.tar.gz" | sha256sum -c && \
    tar -xz -f /tmp/kopia.tar.gz -C /tmp && \
    mv "/tmp/kopia-${KOPIA_VERSION}-linux-${KOPIA_ARCH}/kopia" /usr/bin/kopia && \
    chmod +x /usr/bin/kopia && \
    rm -rf "/tmp/kopia-${KOPIA_VERSION}-linux-${KOPIA_ARCH}" /tmp/kopia.tar.gz && \
    mkdir -p /kopia/cache /kopia/config

RUN if ! command -v node >/dev/null 2>&1 || ! node -e "process.exit(Number(process.versions.node.split('.')[0]) >= 22 ? 0 : 1)"; then \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*; \
  fi

COPY docker/inspect-base.sh /usr/local/bin/inspect-base.sh
RUN chmod +x /usr/local/bin/inspect-base.sh && /usr/local/bin/inspect-base.sh

# Replace bundled umbreld and UI assets with upstream 1.7.3.
RUN rm -rf /opt/umbreld /usr/lib/umbreld /opt/umbrel 2>/dev/null || true
COPY --from=builder /src/packages/umbreld /opt/umbreld
COPY --from=builder /src/packages/ui/dist /opt/umbreld/ui

RUN mkdir -p /usr/lib /opt/umbrel \
  && ln -snf /opt/umbreld /usr/lib/umbreld \
  && ln -snf /opt/umbreld /opt/umbrel/umbreld

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/migrate.sh /usr/local/bin/migrate.sh
COPY docker/rugix-ctrl-stub.sh /usr/local/bin/rugix-ctrl
COPY docker/systemctl-stub.sh /usr/local/bin/systemctl
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/migrate.sh /usr/local/bin/rugix-ctrl /usr/local/bin/systemctl

ENV UMBREL_VERSION=${UMBREL_VERSION}
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/tini", "-s", "/run/entry.sh"]
