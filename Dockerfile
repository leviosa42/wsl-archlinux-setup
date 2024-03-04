FROM docker.io/library/archlinux:latest

SHELL ["/bin/bash", "-c"]

RUN sed -i -e 's|^\(NoExtract *= *usr/share/man/\)|#\1|' /etc/pacman.conf

RUN rm -f /.dockerenv

# COPY --chown=root:root . /build
# RUN time bash /build/setup.sh
