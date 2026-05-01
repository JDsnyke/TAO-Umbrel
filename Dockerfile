FROM node:22-bookworm AS builder

ARG UMBREL_VERSION=1.7.1

WORKDIR /src
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python3 \
    make \
    g++ \
  && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${UMBREL_VERSION}" https://github.com/getumbrel/umbrel /src

WORKDIR /src/packages/ui
RUN npm ci || npm install
RUN npm run build

WORKDIR /src/packages/umbreld
RUN npm ci --omit=dev || npm install --omit=dev


FROM tao9317/tao-umbrel:latest AS final

ARG UMBREL_VERSION=1.7.1

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
  && rm -rf /var/lib/apt/lists/*

RUN if ! command -v node >/dev/null 2>&1 || ! node -e "process.exit(Number(process.versions.node.split('.')[0]) >= 22 ? 0 : 1)"; then \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*; \
  fi

COPY docker/inspect-base.sh /usr/local/bin/inspect-base.sh
RUN chmod +x /usr/local/bin/inspect-base.sh && /usr/local/bin/inspect-base.sh

# Replace bundled umbreld and UI assets with upstream 1.7.1.
RUN rm -rf /opt/umbreld /usr/lib/umbreld /opt/umbrel 2>/dev/null || true
COPY --from=builder /src/packages/umbreld /opt/umbreld
COPY --from=builder /src/packages/ui/dist /opt/umbreld/ui

RUN mkdir -p /usr/lib /opt/umbrel \
  && ln -snf /opt/umbreld /usr/lib/umbreld \
  && ln -snf /opt/umbreld /opt/umbrel/umbreld

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/migrate.sh /usr/local/bin/migrate.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/migrate.sh

ENV UMBREL_VERSION=${UMBREL_VERSION}
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/bin/tini", "-s", "/run/entry.sh"]
