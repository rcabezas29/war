FROM debian:bullseye

RUN apt update && apt upgrade -y

RUN apt install -y gcc make git wget

RUN apt install -y nasm
RUN apt install -y file xxd binwalk binutils gdb strace ltrace watch
RUN git clone https://github.com/radareorg/radare2 && cd radare2 && sys/install.sh 
COPY ./ /home/pestilence
WORKDIR /home/pestilence
CMD ["bash"]
