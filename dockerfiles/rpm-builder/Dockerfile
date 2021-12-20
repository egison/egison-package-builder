FROM centos:latest
MAINTAINER Yamada, Yasuhiro <yamada@gr3.ie>
ENV DEBFULLNAME="Yamada, Yasuhiro" DEBEMAIL=yamada@gr3.ie DEBIAN_FRONTEND=noninteractive
RUN yum install -y rpm-build redhat-rpm-config rpmdevtools

COPY build.sh /tmp/
COPY egison.spec /tmp/
