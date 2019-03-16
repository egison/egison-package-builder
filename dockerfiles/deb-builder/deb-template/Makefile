# DESTDIR is defined in dh_auto_install
# Ref: https://www.debian.org/doc/manuals/maint-guide/modify.ja.html
BINDIR=$(DESTDIR)/usr/bin
BIN1_DEST=bin/tmux-xpanes
BIN2_DEST=bin/xpanes
MANDIR=$(DESTDIR)/usr/share/man/man1
MAN1_DEST=man/tmux-xpanes.1
MAN2_DEST=man/xpanes.1
INSTALL?=/usr/bin/install
RM?=/bin/rm -f

all:
	@echo "Run 'make install' to install"

install:
	${INSTALL} -d ${BINDIR}
	${INSTALL} -m755 ${BIN1_DEST} ${BINDIR}
	${INSTALL} -m755 ${BIN2_DEST} ${BINDIR}
	${INSTALL} -d ${MANDIR}
	${INSTALL} -m644 ${MAN1_DEST} ${MANDIR}
	${INSTALL} -m644 ${MAN2_DEST} ${MANDIR}

uninstall:
	${RM} ${BINDIR}/${BIN1_DEST}
	${RM} ${BINDIR}/${BIN2_DEST}
	${RM} ${MANDIR}/${MAN2_DEST}
	${RM} ${MANDIR}/${MAN2_DEST}

deinstall: uninstall
