# egison-package-builder

Build executable binary file for Egison.
Following files are generated.

* tarball (for x86_64)
* deb file (for Debian base distros)
* RPM file (for Fedora, CentOS, RHEL, Amazon Linux and etc)

This script builds & upload packages if the latest version of Egison have not been built yet.
It runs everyday.

## Script

`release.sh` is the script to build & upload the packages.
It calls following docker containers.

## Docker containers

### `egison-tarball-builder`

* Build Context: `dockerfiles/tarball-builder/`
* Dockerfile location: `Dockerfile`
* Description:
Build executable binary from egison/egison GitHub repository

```
$ docker run <username>/egison-tarball-builder bash /tmp/build.sh <VERSION> > egison.tar.gz
```

### `egison-deb-builder`

* Build Context: `dockerfiles/deb-builder/`
* Dockerfile location: `Dockerfile`
* Description:
Convert tarball to Debian package (deb)

```
$ cat egison.tar.gz | docker run -i <username>/egison-deb-builder bash /tmp/build.sh <VERSION> > egison.deb
```

### `egison-rpm-builder`

* Build Context: `dockerfiles/rpm-builder/`
* Dockerfile location: `Dockerfile`
* Description:
Convert tarball to RPM file.

```
$ cat egison.tar.gz | docker run -i <username>/egison-rpm-builder bash /tmp/build.sh <VERSION> > egison.rpm
```


## How to install packages

### `yum`

```
$ sudo yum install https://.../egison-3.7.14.x86_64.rpm
```

#### Uninstall

```
$ sudo yum remove egison
```

### `apt`

```
$ wget https://.../egison-3.7.14.x86_64.deb
$ sudo apt install ./egison-3.7.14.x86_64.deb
```

#### Uninstall

```
$ sudo apt remove egison
```
