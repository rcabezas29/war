FROM alpine:latest
RUN apk --update add --no-cache \
    bash \
    binutils \
    file \
    gcc \
    gdb \
    git \
    ltrace \
    make \
    nasm \
    strace \
    wget \
    xxd \
    && rm -rf /var/cache/apk/*
COPY ./.devcontainer/.gdbinit /root/.gdbinit
RUN echo set auto-load safe-path / > /root/.gdbinit
SHELL ["/bin/bash", "-c"]
