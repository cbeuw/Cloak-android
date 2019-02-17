# Cloak-android
Shadowsocks plugin Cloak for Android

## Requirements

- Go1.11+
- Android NDK
- Android SDK 26+

## Build Instructions

1. Edit ndk-bundle\build\tools\make_standalone_toolchain.py, change the line `flags = '-target {} -stdlib=libc++'.format(target)` to `flags = '-target {}'.format(target)` (see https://github.com/golang/go/issues/29706)
2. Execute `make.sh`
3. Build with Android Studio
