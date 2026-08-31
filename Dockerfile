FROM ubuntu AS base

ARG DEBIAN_FRONTEND=noninteractive

FROM base AS base-amd64
ENV PATH="$PATH:/usr/local/texlive/2026/bin/x86_64-linux"
RUN touch /root/.bash_profile && \
    touch /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2026/bin/x86_64-linux"\n@' /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2026/bin/x86_64-linux"\n@' /root/.bash_profile

FROM base AS base-arm64
ENV PATH="$PATH:/usr/local/texlive/2026/bin/aarch64-linux"
RUN touch /root/.bash_profile && \
    touch /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2026/bin/aarch64-linux"\n@' /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2026/bin/aarch64-linux"\n@' /root/.bash_profile

ARG TARGETARCH
FROM base-$TARGETARCH AS tlbuild

ENV PATH="$PATH:/root/.local/bin"

WORKDIR /app

COPY profile.input .

# Install texlive and packages
RUN apt-get update && \
    apt-get install -y \
      ssh \
      python-is-python3 \
      pip \
      pipx \
      git \
      wget \
      curl \
      perl \
      libwww-perl \
      libxml-libxslt-perl \
      libbtparse-dev \
      tar \
      make \
      fontconfig \
      locales && \
    pipx install arxiv-collector arxiv_latex_cleaner && \
    wget --no-check-certificate http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    mkdir /tmp/install-tl && \
    tar -xzf install-tl-unx.tar.gz -C /tmp/install-tl --strip-components=1 && \
    /tmp/install-tl/install-tl --profile=/app/profile.input && \
    sed -i '1s@^@export PATH="$PATH:/root/.local/bin"\n@' /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/root/.local/bin"\n@' /root/.bash_profile


RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
