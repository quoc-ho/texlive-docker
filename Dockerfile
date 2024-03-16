FROM ubuntu AS base

ARG DEBIAN_FRONTEND=noninteractive

FROM base AS base-amd64
ENV PATH "$PATH:/usr/local/texlive/2024/bin/x86_64-linux"
RUN touch /root/.bash_profile && \
    touch /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2024/bin/x86_64-linux"\n@' /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2024/bin/x86_64-linux"\n@' /root/.bash_profile

FROM base AS base-arm64
ENV PATH "$PATH:/usr/local/texlive/2024/bin/aarch64-linux"
RUN touch /root/.bash_profile && \
    touch /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2024/bin/aarch64-linux"\n@' /root/.bashrc && \
    sed -i '1s@^@export PATH="$PATH:/usr/local/texlive/2024/bin/aarch64-linux"\n@' /root/.bash_profile

ARG TARGETARCH
FROM base-$TARGETARCH AS tlbuild

WORKDIR /app

COPY profile.input .

# Install texlive and packages
RUN apt-get update && \
    apt-get install -y \
      python-is-python3 \
      pip \
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
    pip install arxiv-collector && \
    cpan App::cpanminus && \
    cpanm Module::Build CPAN::DistnameInfo && \
    cpanm YAML::Tiny File::HomeDir && \ 
    wget --no-check-certificate http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz && \
    mkdir /tmp/install-tl && \
    tar -xzf install-tl-unx.tar.gz -C /tmp/install-tl --strip-components=1 && \
    /tmp/install-tl/install-tl --profile=/app/profile.input

# Compile and install biber 2.19 if not there yet
RUN if [ -z "$(which biber)" ]; then \
        apt-get install -y gcc-aarch64-linux-gnu && \
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

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
