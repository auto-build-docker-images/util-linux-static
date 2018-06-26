# https://github.com/auto-build-docker-images/gcc/blob/master/Dockerfile
FROM osexp2000/gcc as builder

USER root

RUN apt-get update && apt-get -y install libncurses-dev libaudit-dev libselinux-dev

# the reason why not download tgz then decompress is that it cause result binaries lost version info
RUN git clone https://github.com/sjitech/util-linux /util-linux-src

WORKDIR /util-linux-src
#
# build a static linked version (require no system shared lib to run, except nss related command)
#
RUN git checkout v2.32-fix-bug-of-exec_shell
RUN ./autogen.sh && ./configure --with-audit --with-selinux
RUN grep '^#define HAVE_LIB' config.h
# Tools such as sulogin have no way to specify additional -lsepol follow -lselinux
RUN sed -i 's/-lselinux/-lselinux -lsepol -lpcre/g; s/-lselinux -lsepol -lpcre -lsepol/-lselinux/g' Makefile
# Some programs need be linked to libpthread as the last -l option, so use -pthread instead of -lpthead in LDFLAGS.
RUN make LDFLAGS=-all-static CFLAGS="-pthread -DNDEBUG -v" install-strip DESTDIR=/util-linux-dist

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
