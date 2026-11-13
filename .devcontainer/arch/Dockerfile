FROM docker.io/library/node:26-trixie-slim@sha256:5adad64f9a1fca2d51972caa65983634c8a774eb300d72b20f7f2a0f60368072 AS node
FROM ghcr.io/astral-sh/uv:latest@sha256:2bb3ebca0a796a155094a27773d290c4b074572e6107f171d88d086682fd2500 AS uv
FROM ghcr.io/astral-sh/ruff:latest@sha256:3abcaeec575bf06baac8e28f2462e75d7093a7740ecf61c5f833b0a827abac10 AS ruff
FROM docker.io/rhysd/actionlint:latest@sha256:b1934ee5f1c509618f2508e6eb47ee0d3520686341fec936f3b79331f9315667 AS actionlint
FROM docker.io/hadolint/hadolint:latest@sha256:32dac94127fd60b7b7e3fbfc65e1383b9b5e25c9bfd7b8536de7a539fe68a12d AS hadolint

FROM docker.io/library/archlinux:latest@sha256:82b1b08faae9d61e3e7e13d562f4d09114d939105b0d59ff34140f3bd418593a

RUN pacman -Syu --noconfirm --needed base-devel bash-completion ca-certificates curl git jq less openssh python python-pip ripgrep shellcheck sudo unzip wget zip icu openssl unixodbc snappy \
    && pacman -Scc --noconfirm

# Preserve Arch's man directory and share/man symlink when copying Debian's Node tree.
COPY --from=node /usr/local/bin/ /usr/local/bin/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/share/man/ /usr/local/man/
COPY --from=node /usr/local/share/doc/ /usr/local/share/doc/
COPY --from=node /usr/local/LICENSE /usr/local/README.md /usr/local/CHANGELOG.md /usr/local/
COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=ruff /ruff /usr/local/bin/ruff
COPY --from=actionlint /usr/local/bin/actionlint /usr/local/bin/actionlint
COPY --from=hadolint /bin/hadolint /usr/local/bin/hadolint

RUN npm install --global corepack@0.36.0 markdownlint-cli2@0.23.2 \
    && corepack enable \
    && UV_TOOL_DIR=/opt/uv-tools UV_TOOL_BIN_DIR=/usr/local/bin uv tool install zizmor==1.30.0
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ARG PWSH_VERSION=7.4.7
COPY install-pwsh-linux.sh /tmp/install-pwsh-linux.sh
RUN bash /tmp/install-pwsh-linux.sh "${PWSH_VERSION}" && rm /tmp/install-pwsh-linux.sh
ENV POWERSHELL_TELEMETRY_OPTOUT=1
RUN useradd --create-home --shell /bin/bash vscode \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode
WORKDIR /workspace
