FROM node:22.13.0-bookworm AS builder

ARG UMBREL_VERSION=1.7.3

WORKDIR /src
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    patch \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${UMBREL_VERSION}" https://github.com/getumbrel/umbrel /src

COPY docker/patches/umbreld-shared-docker-cleanup.patch /tmp/umbreld-shared-docker-cleanup.patch
COPY docker/patches/umbreld-network-storage-host-mount.patch /tmp/umbreld-network-storage-host-mount.patch
COPY docker/patches/umbreld-device-cpu-fallback.patch /tmp/umbreld-device-cpu-fallback.patch
COPY docker/patches/umbreld-apps-skip-cleanup-retry.patch /tmp/umbreld-apps-skip-cleanup-retry.patch
COPY docker/patches/umbreld-dbus-skip-docker.patch /tmp/umbreld-dbus-skip-docker.patch
COPY docker/patches/umbreld-docker-network-external.patch /tmp/umbreld-docker-network-external.patch
RUN patch -p1 -d /src < /tmp/umbreld-shared-docker-cleanup.patch \
  && patch -p1 -d /src < /tmp/umbreld-network-storage-host-mount.patch \
  && patch -p1 -d /src < /tmp/umbreld-device-cpu-fallback.patch \
  && patch -p1 -d /src < /tmp/umbreld-apps-skip-cleanup-retry.patch \
  && patch -p1 -d /src < /tmp/umbreld-dbus-skip-docker.patch \
  && patch -p1 -d /src < /tmp/umbreld-docker-network-external.patch

WORKDIR /src/packages/umbreld
RUN npm ci || npm install

WORKDIR /src/packages/ui
RUN npm ci || npm install
RUN npm run build

WORKDIR /src/packages/umbreld
RUN rm -rf node_modules && (npm ci --omit=dev || npm install --omit=dev)


FROM tao9317/tao-umbrel:latest AS final

ARG UMBREL_VERSION=1.7.3
ARG TARGETARCH=amd64
ARG KOPIA_VERSION=0.19.0
ARG KOPIA_SHA256_amd64=c07843822c82ec752e5ee749774a18820b858215aabd7da448ce665b9b9107aa
ARG KOPIA_SHA256_arm64=632db9d72f2116f1758350bf7c20aa57c22c220480aaccb5f839e75669210ed9

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Kopia + FUSE for umbreld 1.7.3 backups (upstream umbrelos.Dockerfile); base image may lack these.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    cifs-utils \
    curl \
    fuse3 \
    bindfs \
    util-linux \
  && rm -rf /var/lib/apt/lists/*

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

RUN rm -rf /opt/umbreld /usr/lib/umbreld /opt/umbrel 2>/dev/null || true
COPY --from=builder /src/packages/umbreld /opt/umbreld
COPY --from=builder /src/packages/ui/dist /opt/umbreld/ui

RUN mkdir -p /usr/lib /opt/umbrel \
  && ln -snf /opt/umbreld /usr/lib/umbreld \
  && ln -snf /opt/umbreld /opt/umbrel/umbreld

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/entry.sh /run/entry.sh
COPY docker/rugix-ctrl-stub.sh /usr/local/bin/rugix-ctrl
COPY docker/systemctl-stub.sh /usr/local/bin/systemctl
RUN chmod +x /usr/local/bin/entrypoint.sh /run/entry.sh /usr/local/bin/rugix-ctrl /usr/local/bin/systemctl

ENV UMBREL_VERSION=${UMBREL_VERSION}
ENV UMBREL_DATA_DIR=/data
ENV UMBREL_DISABLE_GLOBAL_DOCKER_CLEANUP=1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/tini", "-s", "/run/entry.sh"]
