FROM phusion/baseimage:latest
MAINTAINER Yamada, Yasuhiro <yamadagrep@gmail.com>
ENV DEBFULLNAME="Yamada, Yasuhiro" DEBEMAIL=yamadagrep@gmail.com DEBIAN_FRONTEND=noninteractive
RUN add-apt-repository -y ppa:hvr/ghc && \
    apt update && \
    apt install -y cabal-install-3.0 ghc-8.8.1 && \
    apt install -y libncurses5-dev git jq xz-utils && \
    ln -s /opt/ghc/bin/ghc /usr/bin/ghc && \
    ln -s /opt/cabal/bin/cabal /usr/bin/cabal

RUN apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY build.sh /tmp
