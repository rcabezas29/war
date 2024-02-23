FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN apt install -y gcc make git wget

RUN apt install -y nasm
RUN apt install -y file xxd binwalk binutils gdb strace ltrace watch
# RUN git clone https://github.com/radareorg/radare2 && cd radare2 && sys/install.sh
RUN wget https://github.com/radareorg/radare2/releases/download/5.8.8/radare2_5.8.8_amd64.deb && \
    dpkg -i radare2_5.8.8_amd64.deb && rm radare2_5.8.8_amd64.deb
RUN echo set auto-load safe-path / > /root/.gdbinit
COPY ./ /home/death
COPY ./.devcontainer/.gdbinit /root/.gdbinit
WORKDIR /home/death
CMD ["bash"]
