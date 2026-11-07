# macOS 26 font crash and slow first save

## Symptom

On macOS 26, Photoshop CS6 crashes with `EXC_BAD_ACCESS` in `ATSLightFontIteratorReset` (called from `AdobeCoolType`), often when saving a file. This happens even with documents that have no text layers, because CoolType builds its font list lazily, the first time anything needs it.

## Cause 1: `ATSFontIteratorReset` crashes

In the x86_64 ATS framework that runs under Rosetta, `ATSFontIteratorCreate` and `ATSFontIteratorNext` still work (they list all ~3000 system fonts), but `ATSFontIteratorReset` segfaults every time. Clearing font caches or removing user fonts does not help.

Fix: interpose `ATSFontIteratorReset` with release-then-create:

```c
ATSFontIteratorRelease(io);
return ATSFontIteratorCreate(ctx, filter, refCon, opts, io);
```

## Cause 2: font cache never saved (slow first save)

CoolType writes the font list to a temporary file and swaps it into `~/Library/Caches/Adobe/TypeSupport/CS6/AdobeFnt_OSFonts.lst` with `PBExchangeObjectsSync`, which calls `exchangedata(2)`. APFS returns `ENOTSUP`, so the cache stays at 0 bytes and every session rescans all fonts (~20 s on the first save).

Fix: when the original call fails, swap the two files' contents in place. Each file keeps its inode, as with `exchangedata`, so CoolType later deletes the temporary file and not the new list. `FSRefParam` uses 2-byte packing: `ioResult` is at offset 28, `ref` at 44 and `newRef` at 92 (read from the CarbonCore disassembly).

## How it is loaded

`DYLD_INSERT_LIBRARIES` set through `LSEnvironment` in `Info.plist` makes macOS 26 refuse to launch the app (Finder: "no permission to open (null)", error -54). Instead, `fix/insert_weak_dylib.py` adds an `LC_LOAD_WEAK_DYLIB` command for `@executable_path/../Frameworks/libATSFix.dylib` to the main executable, which has about 900 bytes of free header space. The executable is then re-signed ad hoc. Because the load is weak, Photoshop still launches if the dylib is missing.
