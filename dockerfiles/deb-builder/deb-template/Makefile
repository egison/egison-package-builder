# DESTDIR is defined in dh_auto_install
# Ref: https://www.debian.org/doc/manuals/maint-guide/modify.ja.html
BINDIR=$(DESTDIR)/usr/bin
BIN_DEST=bin/egison
LIBDIR=$(DESTDIR)/usr/lib
LIB_DEST=lib/egison
INSTALL?=/usr/bin/install
RM?=/bin/rm -rf

all:
	@echo "Run 'make install' to install"

install:
	${INSTALL} -d ${BINDIR}
	${INSTALL} -m 755 ${BIN_DEST} ${BINDIR}
	${INSTALL} -d ${LIBDIR}
	${INSTALL} -m 755 ${LIB_DEST} ${LIBDIR}

uninstall:
	${RM} ${BINDIR}/${BIN_DEST}
	${RM} ${LIBDIR}/${LIB_DEST}

deinstall: uninstall
