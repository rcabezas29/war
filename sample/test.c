#include <stdio.h>
#include <dirent.h>

int main()
{
    DIR *dirp;
    struct dirent *entry;

    dirp = opendir("/proc");
    if (dirp == NULL)
    {
        perror("opendir");
        return -1;
    }

    while ((entry = readdir(dirp)) != NULL)
    {
        printf("Name: %-25s Type: %d\n", entry->d_name, entry->d_type);
    }

    closedir(dirp);
    return 0;
}