FROM phusion/baseimage:latest
MAINTAINER Yamada, Yasuhiro <greengregson@gmail.com>
ENV DEBFULLNAME="Yamada, Yasuhiro" DEBEMAIL=greengregson@gmail.com DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y haskell-platform libncurses5-dev git jq cabal-install ghc

RUN apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY build.sh /tmp
