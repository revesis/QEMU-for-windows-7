#!/bin/bash
set -ex

BUILD_DIR="/tmp/qemu-build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Target Windows 7 (0x0601)
/opt/qemu/configure \
  --cross-prefix=x86_64-w64-mingw32- \
  --target-list=x86_64-softmmu \
  --disable-werror \
  --disable-whpx \
  --enable-hax \
  --disable-gtk \
  --disable-sdl \
  --extra-cflags="-D_WIN32_WINNT=0x0601 -O2"

ninja -j$(nproc)

# Output directory: /dist
mkdir -p /dist

# Copy executables
cp -v qemu-system-x86_64.exe /dist/
cp -v qemu-img.exe /dist/ 2>/dev/null || true
cp -v qemu-io.exe /dist/ 2>/dev/null || true
cp -v qemu-nbd.exe /dist/ 2>/dev/null || true
cp -v qemu-edid.exe /dist/ 2>/dev/null || true

# Copy QEMU firmware/PC-BIOS ROMs (needed by qemu-system-x86_64 to boot VMs!)
mkdir -p /dist/share
cp -rv /opt/qemu/pc-bios/* /dist/share/

# Copy all required MinGW runtime DLLs into /dist
SYSROOT="/usr/x86_64-w64-mingw32/sys-root/mingw/bin"
cp -v $SYSROOT/libglib-2.0-0.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libgobject-2.0-0.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libgmodule-2.0-0.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libgio-2.0-0.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libintl-8.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/iconv.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libpcre-1.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libpcre2-8-0.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libffi-*.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libpixman-1-0.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/zlib1.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libwinpthread-1.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libssp-0.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libgcc_s_seh-1.dll /dist/ 2>/dev/null || true
cp -v $SYSROOT/libstdc++-6.dll /dist/ 2>/dev/null || true

echo "=== Build and packaging complete ==="
ls -lh /dist
