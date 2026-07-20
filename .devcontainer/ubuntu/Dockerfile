# Ubuntu Dev Container — mirrors primary Linux CI host (Debian-family).
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ARG PWSH_VERSION=7.4.7
ENV POWERSHELL_TELEMETRY_OPTOUT=1 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

COPY install-pwsh-linux.sh /tmp/install-pwsh-linux.sh
RUN chmod +x /tmp/install-pwsh-linux.sh \
    && /tmp/install-pwsh-linux.sh "${PWSH_VERSION}" \
    && rm -f /tmp/install-pwsh-linux.sh

WORKDIR /workspace
