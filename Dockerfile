# syntax=docker/dockerfile:1
# Dockerfile to setup beremiz_public_dist build container

FROM ubuntu:noble

ENV TERM xterm-256color

ENV TZ America/Paris
ENV DEBIAN_FRONTEND noninteractive

ARG UNAME=runner
ENV UNAME ${UNAME}
ARG UID=1000
ARG GID=1000

RUN sed -i "/$GID/d" /etc/group
RUN sed -i "/$UID/d" /etc/passwd

RUN groupadd -g $GID $UNAME
RUN useradd -m -u $UID -g $GID -s /bin/bash $UNAME

COPY ./provision_noble64.sh .

RUN ./provision_noble64.sh

# easy to remember 'build' alias to invoke main makefile
ARG OWNDIRBASENAME=beremiz_public_dist
ENV OWNDIRBASENAME ${OWNDIRBASENAME}
RUN cat > /usr/local/bin/build <<'EOF'
#!/bin/bash

set -e

TMP_BUILD_DIR=$(mktemp -d -t beremiz_dist_build_tmp.XXXXXXXXXX)

cleanup() {
    rm -rf -- "$TMP_BUILD_DIR"
}

trap cleanup EXIT

make -f "/home/${UNAME}/src/${OWNDIRBASENAME}/Makefile" \
    "tmp=$TMP_BUILD_DIR" "$@"
EOF

RUN chmod +x /usr/local/bin/build

USER $UNAME

RUN mkdir /home/$UNAME/build /home/$UNAME/src
