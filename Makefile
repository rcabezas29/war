# **************************************************************************** #
#                                   PROGRAM                                    #
# **************************************************************************** #

NAME = $(BUILD_DIR)/pestilence

# **************************************************************************** #
#                                     VARS                                     #
# **************************************************************************** #

CP = cp
MV = mv
MKDIR = mkdir -p
RM = rm -rf

# **************************************************************************** #
#                                   LINKER                                     #
# **************************************************************************** #

LD = ld

# **************************************************************************** #
#                                   COMPILER                                   #
# **************************************************************************** #

NASM = nasm

# **************************************************************************** #
#                                    FLAGS                                     #
# **************************************************************************** #

FLAGS = -f elf64 -O0

# **************************************************************************** #
#                                   SOURCES                                    #
# **************************************************************************** #

BUILD_DIR := build
SRC_DIR := srcs
INC_DIR := includes
LIB_DIR := lib

SRCS := $(SRC_DIR)/pestilence.s
OBJS := $(SRCS:%.s=$(BUILD_DIR)/%.o)

all: $(NAME)

$(NAME): $(OBJS)
	$(LD) -o $@ $(OBJS)

$(BUILD_DIR)/%.o: %.s
	mkdir -p $(dir $@)
	$(NASM) $(FLAGS) -o $@ $<

clean:
	$(RM) $(OBJS)

fclean: clean
	$(RM) $(BUILD_DIR)

s: $(NAME)
	strace ./build/pestilence

g: $(NAME)
	gdb ./build/pestilence

run: $(NAME)
	mkdir -p /tmp/test
	cp /bin/c* /tmp/test/
	strace -x ./build/pestilence
bw: $(NAME)
	cp /bin/cp /tmp/test/cp
	cp ./sample/a.out /tmp/test/a.out
	./$(NAME)
	binwalk -W ./sample/a.out /tmp/test/a.out
re:: fclean all

.PHONY: all clean fclean re
