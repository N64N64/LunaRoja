require('plat.'..PLATFORM..'.cdef')
require 'cdef.mgba'

if jit.status() then
    ffi.cdef[[
    void PC_HOOK(int bank, int addr, bool (*callback)());
    ]]
    function PC_HOOK(...)
        return ffi.mgba.PC_HOOK(...)
    end
elseif not PC_HOOK then
    error('PC_HOOK not predefined')
end

ffi.cdef[[

// std

void printf(const char *fmt, ...);
void * memcpy(void *, void *, size_t);
void *memset(void *s, int c, size_t n);
size_t recv(int sockfd, void *buf, size_t len, int flags);
int strncmp ( const char * str1, const char * str2, size_t num );
int memcmp ( const void * ptr1, const void * ptr2, size_t num );
void free(void *);

typedef void FILE;
int fseek(FILE *stream, long offset, int whence);
void rewind(FILE *stream);
FILE * fopen ( const char * filename, const char * mode );
size_t fread ( void * ptr, size_t size, size_t count, FILE * stream );
int fclose ( FILE * stream );
long int ftell ( FILE * stream );

// stb

typedef unsigned char stbi_uc;
stbi_uc *stbi_load               (char              const *filename,           int *x, int *y, int *comp, int req_comp);
const char *stbi_failure_reason  (void);
void     stbi_image_free      (void *retval_from_stbi_load);
int stbi_write_png(char const *filename, int w, int h, int comp, const void *data, int stride_in_bytes);
typedef void stbi_write_func(void *context, void *data, int size);
int stbi_write_png_to_func(stbi_write_func *func, void *context, int w, int h, int comp, const void  *data, int stride_in_bytes);

// sha256

typedef struct SHA256_CTX {
    unsigned char data[64];
    unsigned int datalen;
    unsigned long long bitlen;
    unsigned char state[8];
} SHA256_CTX;
void sha256_init(SHA256_CTX *ctx);
void sha256_update(SHA256_CTX *ctx, const unsigned char data[], size_t len);
void sha256_final(SHA256_CTX *ctx, unsigned char hash[]);

// my stuff

void lovecopy(uint8_t *out, uint8_t *in, int size);
void fastcopy(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int  inh);
void fastcopyaf(uint8_t *out, int outw, int outh, int outx, int outy,
               uint8_t *in, int  inw, int inh, uint8_t invis, bool flip);
int minstride_override;
void scalecopy(uint8_t *out, uint8_t *in, int width, int height, float scale);
void mgbacopy(uint8_t *out, int outw, int outh, int outx, int outy,
              uint8_t *in,  int inw,  int inh,  int  inx, int  iny);
void rotatecopy(uint8_t *out, int outw, int outh, int outstride, int outx, int outy,
                uint8_t *in,  int inw,  int inh,  int instride,  int inx,  int iny);
void makebgr(uint8_t *pix, int width, int height, int channels);
void draw_set_color(uint8_t r, uint8_t g, uint8_t b);
void draw_circle(uint8_t *fb, int fbwidth, int fbheight, float x0, float y0, float radius, bool should_outline);
void draw_rect(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy, float fwidth, float fheight);
bool draw_pixel(uint8_t *fb, int fbwidth, int fbheight, float fx, float fy);
void draw_line(uint8_t *fb, int fbwidth, int fbheight, float x1, float y1, float x2, float y2);
void * font_create(const char *path);
void font_dimensions(void *font, const char *text, int size, int *outwidth, int *outheight);
uint8_t * font_render(void *font, const char *text, int size, int *outwidth, int *outheight);
bool untargz(const char *filename, const char *outfolder);

]]
