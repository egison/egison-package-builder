FROM phusion/baseimage:latest
MAINTAINER Yamada, Yasuhiro <yamadagrep@gmail.com>
ENV DEBFULLNAME="Yamada, Yasuhiro" DEBEMAIL=yamadagrep@gmail.com DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y dh-make fakeroot pbuilder software-properties-common jq

RUN apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY deb-template /tmp/deb-template
COPY build.sh /tmp
COPY changelog.sh /tmp
