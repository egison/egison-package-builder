FROM centos:latest
MAINTAINER Yamada, Yasuhiro <greengregson@gmail.com>
ENV DEBFULLNAME="Yamada, Yasuhiro" DEBEMAIL=greengregson@gmail.com DEBIAN_FRONTEND=noninteractive
RUN yum install -y rpm-build redhat-rpm-config rpmdevtools

COPY build.sh /tmp/
COPY egison.spec /tmp/
