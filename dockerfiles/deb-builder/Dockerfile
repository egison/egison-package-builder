FROM phusion/baseimage:18.04-1.0.0-amd64
MAINTAINER Yamada, Yasuhiro <yamada@gr3.ie>
ENV DEBFULLNAME="Yamada, Yasuhiro" DEBEMAIL=yamada@gr3.ie DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y dh-make fakeroot pbuilder software-properties-common jq

RUN apt clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY deb-template /tmp/deb-template
COPY build.sh /tmp
COPY changelog.sh /tmp
