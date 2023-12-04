#define _GNU_SOURCE
#include <unistd.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>  // For definition of struct linux_dirent64
#include <elf.h>


#define BUF_SIZE 1024

struct linux_dirent64 {
    ino64_t        d_ino;    /* 64-bit inode number */
    off64_t        d_off;    /* 64-bit offset to next structure */
    unsigned short d_reclen; /* Size of this dirent */
    unsigned char  d_type;   /* File type */
    char           d_name[]; /* Filename (null-terminated) */
};


int main(void) {
    Elf64_Ehdr *s;
    loff_t  pos;

    sizeof(Elf64_Phdr);
    int fd, nread;
    char buf[BUF_SIZE];
    struct linux_dirent64 *d;
    int bpos;
    char d_type;
    struct stat statbuf;

    fd = open(".", O_RDONLY | O_DIRECTORY);
    if (fd == -1) {
        perror("open");
        exit(EXIT_FAILURE);
    }

    for (;;) {
        nread = syscall(SYS_getdents64, fd, buf, BUF_SIZE);
        if (nread == -1) {
            perror("getdents64");
            exit(EXIT_FAILURE);
        }

        if (nread == 0)
            break;

        for (bpos = 0; bpos < nread;) {
            d = (struct linux_dirent64 *) (buf + bpos);
            printf("%s ", d->d_name);

            if (stat(d->d_name, &statbuf) != -1) {
                printf("(mode: 0x%x)\n", statbuf.st_mode);

                    // Check read permission
                    int re=S_IRUSR;
                    int wr= S_IWUSR;
    if (statbuf.st_mode & S_IRUSR) {
        printf("Read: Yes ");
    } else {
        printf("Read: No ");
    }

    // Check write permission
    if (statbuf.st_mode & S_IWUSR) {
        printf("Write: Yes\n");
    } else {
        printf("Write: No\n");
    }
            } else {
                perror("stat");
            }

            bpos += d->d_reclen;
        }
    }

    close(fd);
    exit(EXIT_SUCCESS);
}

