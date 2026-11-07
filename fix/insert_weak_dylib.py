import struct, sys

path, dylib = sys.argv[1], sys.argv[2].encode() + b'\0'
b = bytearray(open(path, 'rb').read())
magic, cpu, sub, ft, ncmds, sz, flags, res = struct.unpack_from('<IiiIIIII', b, 0)
assert magic == 0xfeedfacf
end = 32 + sz
off = 32
first = len(b)
for i in range(ncmds):
    cmd, cs = struct.unpack_from('<II', b, off)
    if cmd == 0x19:  # LC_SEGMENT_64
        nsect = struct.unpack_from('<I', b, off + 64)[0]
        for j in range(nsect):
            so = struct.unpack_from('<I', b, off + 72 + j * 80 + 48)[0]
            if so:
                first = min(first, so)
    off += cs
name_off = 24
cs = (name_off + len(dylib) + 7) // 8 * 8
assert end + cs <= first, (end, cs, first)
assert b[end:end + cs] == b'\0' * cs
# LC_LOAD_WEAK_DYLIB: missing lib won't block launch
cmd = struct.pack('<IIIIII', 0x80000018, cs, name_off, 2, 0x10000, 0x10000) + dylib
cmd += b'\0' * (cs - len(cmd))
b[end:end + cs] = cmd
struct.pack_into('<II', b, 16, ncmds + 1, sz + cs)
open(path, 'wb').write(b)
print("inserted", cs, "bytes; free left", first - end - cs)
