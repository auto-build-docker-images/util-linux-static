FROM osexp2000/gcc as builder

USER root

RUN apt-get update && apt-get -y install libncurses-dev libaudit-dev libselinux-dev

# the reason why not download tgz then decompress is that it cause result binaries lost version info
RUN git clone https://github.com/karelzak/util-linux /util-linux-src

WORKDIR /util-linux-src
#
# build a static linked version (require no system shared lib to run, except nss related command)
#
RUN git checkout v2.35.1
RUN ./autogen.sh && ./configure --with-audit --with-selinux
RUN grep '^#define HAVE_LIB' config.h
# Some programs need be linked to libpthread as the last -l option, so use -pthread instead of -lpthead in LDFLAGS.
RUN make LDFLAGS=-all-static LIBS="-lselinux -lsepol -lpcre -lcap-ng" CFLAGS="-pthread -DNDEBUG -v" install-strip DESTDIR=/util-linux-dist

WORKDIR /util-linux-dist

# rename some duplicated *.static files
RUN bash -c 'find . -type f -name *.static | while read f; do mv $f ${f%.static}; done'

# bash is installed in /usr/local/bin, so I have to link it to bin/
RUN ln -s ../usr/local/bin/bash bin/

###############################################################################

FROM bash

COPY --from=builder /util-linux-dist /

ENTRYPOINT []
CMD ["/bin/bash"]
