FROM ubuntu

WORKDIR /app

# texlive arch: aarch64-linux or 
ARG TLARCH 

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

ENV PATH "$PATH:/usr/local/texlive/2023/bin/$TLARCH"

# Compile and install biber 2.19
RUN if test -f $(which biber); then \
        echo "biber is already installed with texlive!"; \
    else \
        git clone https://github.com/plk/biber.git && \
        cd biber && \
        git checkout v2.19 && \
        perl Build.PL && \
        ./Build installdeps && \
        ./Build install && \
        cd .. && \
        rm -rf biber; \
    fi

RUN apt-get clean -y
