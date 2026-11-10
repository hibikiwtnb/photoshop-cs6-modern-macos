# Font crash and slow first save on modern macOS

Install the ATS fix on every modern macOS version supported by this project, including Sequoia 15 and macOS 26, on Intel and Apple Silicon. The installer retains its original filename, `Install-macOS26-Fix.command`.

## Symptom

Photoshop CS6 can crash with `EXC_BAD_ACCESS` in `ATSLightFontIteratorReset`, called by `AdobeCoolType` through `ATSFontIteratorReset`. The same stack was observed on Intel Sequoia 15.7.7 and on macOS 26.5 with Rosetta on an M2. Saving a file can trigger it even without text layers because CoolType builds its font list on demand.

## Cause 1: `ATSFontIteratorReset` crashes

On the tested Rosetta system, `ATSFontIteratorCreate` and `ATSFontIteratorNext` still enumerate fonts while `ATSFontIteratorReset` segfaults. The Intel Sequoia crash report also places the fault inside the reset call.

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
