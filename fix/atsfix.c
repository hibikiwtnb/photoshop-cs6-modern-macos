// Photoshop CS6 fixes for macOS 26 (x86_64 under Rosetta), loaded via LC_LOAD_WEAK_DYLIB.
//
// 1. ATSFontIteratorReset crashes. Replace it with Release + Create, which still work.
// 2. PBExchangeObjectsSync uses exchangedata(2), which APFS does not support, so
//    CoolType can never save its font list cache (AdobeFnt_OSFonts.lst stays 0 bytes)
//    and rebuilds it (~20s) every session. Emulate exchangedata by swapping file
//    contents in place, keeping each file's identity (inode), like the original.
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

typedef int32_t OSStatus; typedef int16_t OSErr; typedef void *ATSFontIterator;
typedef struct { uint8_t hidden[80]; } FSRef_;

extern OSStatus ATSFontIteratorCreate(uint32_t, void *, void *, uint32_t, ATSFontIterator *);
extern OSStatus ATSFontIteratorReset(uint32_t, void *, void *, uint32_t, ATSFontIterator *);
extern OSStatus ATSFontIteratorRelease(ATSFontIterator *);
extern OSErr PBExchangeObjectsSync(void *pb);
extern OSStatus FSRefMakePath(const FSRef_ *, uint8_t *, uint32_t);

static OSStatus fixed_Reset(uint32_t ctx, void *filter, void *refCon, uint32_t opts, ATSFontIterator *io) {
  if (!io) return -50; /* paramErr */
  if (*io) ATSFontIteratorRelease(io);
  *io = 0;
  return ATSFontIteratorCreate(ctx, filter, refCon, opts, io);
}

static int read_all(const char *p, char **buf, size_t *len) {
  int fd = open(p, O_RDONLY); if (fd < 0) return -1;
  struct stat st; if (fstat(fd, &st)) { close(fd); return -1; }
  *len = (size_t)st.st_size; *buf = malloc(*len ? *len : 1);
  size_t got = 0;
  while (got < *len) { ssize_t n = read(fd, *buf + got, *len - got); if (n <= 0) break; got += (size_t)n; }
  close(fd);
  if (got != *len) { free(*buf); return -1; }
  return 0;
}

static int write_all(const char *p, const char *buf, size_t len) {
  int fd = open(p, O_WRONLY | O_TRUNC); if (fd < 0) return -1;
  size_t put = 0;
  while (put < len) { ssize_t n = write(fd, buf + put, len - put); if (n <= 0) break; put += (size_t)n; }
  close(fd);
  return put == len ? 0 : -1;
}

// FSRefParam is #pragma pack(2): ioResult @28, ref @44, newRef @92 (from CarbonCore disassembly).
static OSErr fixed_Exchange(void *pb) {
  OSErr r = PBExchangeObjectsSync(pb);
  if (r == 0) return 0;
  const FSRef_ *a, *b;
  memcpy(&a, (char *)pb + 44, sizeof a);
  memcpy(&b, (char *)pb + 92, sizeof b);
  if (!a || !b) return r;
  uint8_t pa[1024], pbp[1024];
  if (FSRefMakePath(a, pa, sizeof pa) || FSRefMakePath(b, pbp, sizeof pbp)) return r;
  char *ba = 0, *bb = 0; size_t la = 0, lb = 0;
  if (read_all((char *)pa, &ba, &la)) return r;
  if (read_all((char *)pbp, &bb, &lb)) { free(ba); return r; }
  OSErr out = 0;
  if (write_all((char *)pa, bb, lb) || write_all((char *)pbp, ba, la)) out = -36; /* ioErr */
  free(ba); free(bb);
  memcpy((char *)pb + 28, &out, sizeof out);
  return out;
}

__attribute__((used, section("__DATA,__interpose")))
static struct { const void *repl, *orig; } interposers[] = {
  { (const void *)fixed_Reset, (const void *)ATSFontIteratorReset },
  { (const void *)fixed_Exchange, (const void *)PBExchangeObjectsSync },
};
