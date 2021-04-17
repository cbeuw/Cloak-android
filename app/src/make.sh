#!/usr/bin/env bash

function getHostTag() {
  # Copyright (C) 2010 The Android Open Source Project
  # Modified by Andy Wang (cbeuw.andy@gmail.com)
  #
  # Licensed under the Apache License, Version 2.0 (the "License");
  # you may not use this file except in compliance with the License.
  # You may obtain a copy of the License at
  #
  #      http://www.apache.org/licenses/LICENSE-2.0
  #
  # Detect host operating system and architecture
  # The 64-bit / 32-bit distinction gets tricky on Linux and Darwin because
  # uname -m returns the kernel's bit size, and it's possible to run with
  # a 64-bit kernel and a 32-bit userland.
  #
  HOST_OS=$(uname -s)
  case $HOST_OS in
  Darwin) HOST_OS=darwin ;;
  Linux) HOST_OS=linux ;;
  FreeBsd) HOST_OS=freebsd ;;
  CYGWIN* | *_NT-*) HOST_OS=windows ;;
  *)
    echo "ERROR: Unknown host operating system: $HOST_OS"
    exit 1
    ;;
  esac
  echo "HOST_OS=$HOST_OS"

  HOST_ARCH=$(uname -m)
  case $HOST_ARCH in
  i?86) HOST_ARCH=x86 ;;
  x86_64 | amd64) HOST_ARCH=x86_64 ;;
  *)
    echo "ERROR: Unknown host CPU architecture: $HOST_ARCH"
    exit 1
    ;;
  esac
  echo "HOST_ARCH=$HOST_ARCH"

  # Detect 32-bit userland on 64-bit kernels
  HOST_TAG="$HOST_OS-$HOST_ARCH"
  case $HOST_TAG in
  linux-x86_64 | darwin-x86_64)
    # we look for x86_64 or x86-64 in the output of 'file' for our shell
    # the -L flag is used to dereference symlinks, just in case.
    file -L "$SHELL" | grep -q "x86[_-]64"
    if [ $? != 0 ]; then
      HOST_ARCH=x86
      HOST_TAG=$HOST_OS-x86
      echo "HOST_ARCH=$HOST_ARCH (32-bit userland detected)"
    fi
    ;;
  esac
  # Check that we have 64-bit binaries on 64-bit system, otherwise fallback
  # on 32-bit ones. This gives us more freedom in packaging the NDK.
  if [ $HOST_ARCH = x86_64 -a ! -d $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG ]; then
    HOST_TAG=$HOST_OS-x86
    if [ $HOST_TAG = windows-x86 ]; then
      HOST_TAG=windows
    fi
    echo "HOST_TAG=$HOST_TAG (no 64-bit prebuilt binaries detected)"
  else
    echo "HOST_TAG=$HOST_TAG"
  fi
}

#Copyright (C) 2017 by Max Lv <max.c.lv@gmail.com>
#Copyright (C) 2017 by Mygod Studio <contact-shadowsocks-android@mygod.be>
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

function try() {
  "$@" || exit -1
}

pushd ../..
"${ANDROID_NDK_HOME:=$(./gradlew -q printNDKPath)}"
CK_RELEASE_TAG=v"$(./gradlew -q printVersionName)"
popd

while [ ! -d "$ANDROID_NDK_HOME" ]; do
  echo "Path to ndk-bundle not found"
  exit -1
done

getHostTag
MIN_API=21
ANDROID_PREBUILT_TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG

ANDROID_ARM_CC=$ANDROID_PREBUILT_TOOLCHAIN/bin/armv7a-linux-androideabi${MIN_API}-clang

ANDROID_ARM64_CC=$ANDROID_PREBUILT_TOOLCHAIN/bin/aarch64-linux-android21-clang
ANDROID_ARM64_STRIP=$ANDROID_PREBUILT_TOOLCHAIN/bin/aarch64-linux-android-strip

ANDROID_X86_CC=$ANDROID_PREBUILT_TOOLCHAIN/bin/i686-linux-android${MIN_API}-clang
ANDROID_X86_STRIP=$ANDROID_PREBUILT_TOOLCHAIN/bin/i686-linux-android-strip

ANDROID_X86_64_CC=$ANDROID_PREBUILT_TOOLCHAIN/bin/x86_64-linux-android${MIN_API}-clang
ANDROID_X86_64_STRIP=$ANDROID_PREBUILT_TOOLCHAIN/bin/x86_64-linux-android-strip

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS=$(pwd)/.deps
try mkdir -p $DEPS $SRC_DIR/main/jniLibs/armeabi-v7a $SRC_DIR/main/jniLibs/x86 $SRC_DIR/main/jniLibs/arm64-v8a $SRC_DIR/main/jniLibs/x86_64

try cd $DEPS
echo "Getting Cloak source code"
rm -rf Cloak
try git clone https://github.com/cbeuw/Cloak
cd Cloak
try git checkout tags/$CK_RELEASE_TAG
try go get ./...

cd cmd/ck-client

echo "Cross compiling ckclient for arm"
try env CGO_ENABLED=1 CC="$ANDROID_ARM_CC" GOOS=android GOARCH=arm GOARM=7 go build -ldflags="-s -w"
try mv ck-client $SRC_DIR/main/jniLibs/armeabi-v7a/libck-client.so

echo "Cross compiling ckclient for arm64"
try env CGO_ENABLED=1 CC="$ANDROID_ARM64_CC" GOOS=android GOARCH=arm64 go build -ldflags="-s -w"
try "$ANDROID_ARM64_STRIP" ck-client
try mv ck-client $SRC_DIR/main/jniLibs/arm64-v8a/libck-client.so

echo "Cross compiling ckclient for x86"
try env CGO_ENABLED=1 CC="$ANDROID_X86_CC" GOOS=android GOARCH=386 go build -ldflags="-s -w"
try "$ANDROID_X86_STRIP" ck-client
try mv ck-client $SRC_DIR/main/jniLibs/x86/libck-client.so

echo "Cross compiling ckclient for x86_64"
try env CGO_ENABLED=1 CC="$ANDROID_X86_64_CC" GOOS=android GOARCH=amd64 go build -ldflags="-s -w"
try "$ANDROID_X86_64_STRIP" ck-client
try mv ck-client $SRC_DIR/main/jniLibs/x86_64/libck-client.so

echo "Success"
