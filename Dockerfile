FROM ubuntu AS base

FROM base AS base-amd64
ENV PATH "$PATH:/usr/local/texlive/2023/bin/x86_64-linux"

FROM base AS base-arm64
ENV PATH "$PATH:/usr/local/texlive/2023/bin/aarch64-linux"

ARG TARGETARCH
FROM base-$TARGETARCH AS tlbuild

WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive

COPY profile.input .

# Install texlive and packages
RUN apt-get update && \
    apt-get install -y \
      python-is-python3 \
      pip \
      git \
      wget \
      perl \
      libwww-perl \
      libxml-libxslt-perl \
      libbtparse-dev \
      tar \
      make \
      gcc-aarch64-linux-gnu \
      fontconfig \
      locales && \
    pip install arxiv-collector && \
    cpan App::cpanminus && \
    cpanm Module::Build CPAN::DistnameInfo && \
    wget --no-check-certificate http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    mkdir /tmp/install-tl && \
    tar -xzf install-tl-unx.tar.gz -C /tmp/install-tl --strip-components=1 && \
    /tmp/install-tl/install-tl --profile=/app/profile.input

# Compile and install biber 2.19 if not there yet
RUN if [ -z "$(which biber)" ]; then \
        git clone https://github.com/plk/biber.git && \
        cd biber && \
        git checkout v2.19 && \
        perl Build.PL && \
        ./Build installdeps && \
        ./Build install && \
        cd .. && \
        rm -rf biber ; \
    else \
        echo "biber is already installed with texlive!" ; \
    fi

RUN apt-get clean -y
