# QEMU Windows 7 Compatibility Patch & Build Guide

## 1. Patch Details

The core reasons why modern QEMU cannot run on Windows 7 and the changes introduced by this patch are as follows:

### 1. Lowering the Target Platform Macro (`include/qemu/osdep.h`)
* The original codebase sets `_WIN32_WINNT` to `0x0602` (Windows 8), preventing building and running on Windows 7.
* **Change**: Adjusted to `0x0601` (Windows 7 API).

### 2. Dynamic Fallback for Futex Synchronization (`include/qemu/futex.h` and `util/oslib-win32.c`)
* The original codebase statically calls the Windows 8+ APIs `WaitOnAddress`, `WakeByAddressSingle`, and `WakeByAddressAll`, which triggers the error `The procedure entry point WaitOnAddress could not be located in the dynamic link library KERNEL32.dll` on Windows 7.
* **Change**:
  * Dynamically detect at runtime whether `WaitOnAddress` is supported via `GetProcAddress`.
  * When running on Windows 8/10/11, continue using the native fast path.
  * When running on Windows 7 (the function pointer is NULL), automatically fall back to a hashed-bucket implementation based on `SRWLOCK` + `CONDITION_VARIABLE` (natively supported on Windows Vista / Windows 7, with zero external dependencies).

---

## 2. Patch File and Branch

* **Branch**: `win7-compat`
* **Patch File**: `0001-win7-add-Windows-7-compatibility-fallback-for-futex-.patch`

To apply this patch to another cloned tree:
```bash
git am 0001-win7-add-Windows-7-compatibility-fallback-for-futex-.patch
```

---

## 3. Dependency Selection: GLib 2.66.8 (Option A)

The QEMU build system (`meson.build`) requires a minimum GLib version:
```python
glib_req_ver = '>=2.66.0'
```
**GLib 2.66.8** satisfies QEMU's `>=2.66.0` threshold while remaining the last official GNOME stable release with full Windows 7 support (versions 2.68+ shifted towards Windows 8+ APIs).

Recommended dependency versions when building the toolchain:
* **GLib**: 2.66.8
* **Pixman**: 0.40.0 or 0.42.x
* **Zlib**: 1.2.13 / 1.3.x
* **Libslirp**: 4.7.0 (for user-mode networking `-net user`)

---

## 4. Cross-Compilation Reference

Run the following on a build machine configured with a MinGW-w64 and GLib 2.66 cross-compilation environment:

```bash
mkdir build-win7 && cd build-win7

../configure \
  --cross-prefix=x86_64-w64-mingw32- \
  --target-list=x86_64-softmmu \
  --disable-werror \
  --disable-whpx \
  --enable-slirp \
  --extra-cflags="-D_WIN32_WINNT=0x0601"

ninja
```

Once compilation succeeds, package the resulting `qemu-system-x86_64.exe` along with the required dependency DLLs (`libglib-2.0-0.dll`, etc.) to run directly on Windows 7.
