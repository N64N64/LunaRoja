#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#ifdef _3DS
// minimal zlib.h
typedef void *gzFile;
typedef long z_off_t;
gzFile gzopen(const char*, const char*);
int gzread(gzFile, void *, unsigned);
z_off_t gzseek(gzFile, z_off_t, int whence);
int gzclose(gzFile);
#else
#include <zlib.h>
#endif


#define MIN(a, b) (a < b ? a : b)

bool untargz(const char *filename, const char *outfolder)
{
    gzFile f = gzopen(filename, "rb");

    if(f == NULL) {
        return false;
    }

    while(true) {
        char name[100];
        gzread(f, name, 100);

        gzseek(f, 24, SEEK_CUR);

        char size[12];
        gzread(f, size, 12);
        long siz = strtol(size, NULL, 8);
        if(siz == 0) {
            break;
        }

        char path[100 + strlen(outfolder) + 2];
        strcpy(path, outfolder);
        strcat(path, "/");
        strcat(path, name);
        FILE *outf = fopen(path, "w");
        if(outf == NULL) {
            return false;
        }

        gzseek(f, 376, SEEK_CUR);

        long remaining = siz;
        char contents[512];
        while(remaining > 0) {
            int len = MIN(512, remaining);
            gzread(f, contents, len);
            fwrite(contents, len, 1, outf);
            remaining = remaining - len;
        }
        fclose(outf);

        gzseek(f, 512 - (siz % 512), SEEK_CUR);
    }
    gzclose(f);
    return true;
}
