FROM centos:latest
MAINTAINER Yamada, Yasuhiro <yamadagrep@gmail.com>
ENV DEBFULLNAME="Yamada, Yasuhiro" DEBEMAIL=yamadagrep@gmail.com DEBIAN_FRONTEND=noninteractive
RUN yum install -y rpm-build redhat-rpm-config rpmdevtools

COPY build.sh /tmp/
COPY egison.spec /tmp/
