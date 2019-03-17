# egison-package-builder

Build executable binary file for Egison.
Following files are generated.

* tarball
* deb file (for Debian base distros)
* RPM file (for Fedora, CentOS, RHEL, Amazon Linux and etc)

This script builds & upload packages if the latest version of Egison have not been built yet.
It runs everyday.

## Script

`release.sh` is the script to build & upload the packages.
It calls following docker containers.

## Docker containers

* egison-tarball-builder

```
$ docker run egison-tarball-builder bash /tmp/build.sh <VERSION> > egison.tar.gz
```

* egison-deb-builder

```
$ docker run egison-tarball-builder bash /tmp/build.sh <VERSION> > egison.deb
```

tarball must be uploaded in advance.

* egison-rpm-builder

```
$ docker run egison-tarball-builder bash /tmp/build.sh <VERSION> > egison.rpm
```

tarball must be uploaded in advance.
