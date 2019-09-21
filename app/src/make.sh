#!/usr/bin/env bash

#Copyright (C) 2017 by Max Lv <max.c.lv@gmail.com>
#Copyright (C) 2017 by Mygod Studio <contact-shadowsocks-android@mygod.be>
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.



function try () {
"$@" || exit -1
}

[ -z "$ANDROID_NDK_HOME" ] && ANDROID_NDK_HOME=$ANDROID_HOME/ndk-bundle

if [ ! -d "$ANDROID_SDK_PATH" ]; then
ANDROID_NDK_HOME=$USERPROFILE/AppData/Local/Android/Sdk/ndk-bundle
fi

while [ ! -d "$ANDROID_NDK_HOME" ]; do
echo "Path to ndk-bundle not found. Please enter the full path"
read -p '' ANDROID_NDK_HOME
done


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MIN_API=21
DEPS=$(pwd)/.deps
ANDROID_ARM_TOOLCHAIN=$DEPS/android-toolchain-${MIN_API}-arm
ANDROID_ARM64_TOOLCHAIN=$DEPS/android-toolchain-21-arm64
ANDROID_X86_TOOLCHAIN=$DEPS/android-toolchain-${MIN_API}-x86

ANDROID_ARM_CC=$ANDROID_ARM_TOOLCHAIN/bin/arm-linux-androideabi-clang
ANDROID_ARM_STRIP=$ANDROID_ARM_TOOLCHAIN/bin/arm-linux-androideabi-strip

ANDROID_ARM64_CC=$ANDROID_ARM64_TOOLCHAIN/bin/aarch64-linux-android-clang
ANDROID_ARM64_STRIP=$ANDROID_ARM64_TOOLCHAIN/bin/aarch64-linux-android-strip

ANDROID_X86_CC=$ANDROID_X86_TOOLCHAIN/bin/i686-linux-android-clang
ANDROID_X86_STRIP=$ANDROID_X86_TOOLCHAIN/bin/i686-linux-android-strip

try mkdir -p $DEPS $DIR/main/jniLibs/armeabi-v7a $DIR/main/jniLibs/x86 $DIR/main/jniLibs/arm64-v8a

if [ ! -f "$ANDROID_ARM_CC" ]; then
    echo "Make standalone toolchain for ARM arch"
    $ANDROID_NDK_HOME/build/tools/make_standalone_toolchain.py --arch arm \
        --api $MIN_API --install-dir $ANDROID_ARM_TOOLCHAIN
fi

if [ ! -f "$ANDROID_ARM64_CC" ]; then
    echo "Make standalone toolchain for ARM64 arch"
    $ANDROID_NDK_HOME/build/tools/make_standalone_toolchain.py --arch arm64 \
        --api 21 --install-dir $ANDROID_ARM64_TOOLCHAIN
fi

if [ ! -f "$ANDROID_X86_CC" ]; then
    echo "Make standalone toolchain for X86 arch"
    $ANDROID_NDK_HOME/build/tools/make_standalone_toolchain.py --arch x86 \
        --api $MIN_API --install-dir $ANDROID_X86_TOOLCHAIN
fi

pushd $DEPS
echo "Getting Cloak source code"
rm -rf Cloak
GO111MOD=on
git clone https://github.com/cbeuw/Cloak
pushd Cloak
go get

pushd cmd/ck-client

echo "Cross compile ckclient for arm"
echo $ANDROID_ARM_CC
try env CGO_ENABLED=1 CC=$ANDROID_ARM_CC GOOS=android GOARCH=arm GOARM=7 go build -ldflags="-s -w"
try $ANDROID_ARM_STRIP ck-client
try mv ck-client $DIR/main/jniLibs/armeabi-v7a/libck-client.so

echo "Cross compile ckclient for arm64"
try env CGO_ENABLED=1 CC=$ANDROID_ARM64_CC GOOS=android GOARCH=arm64 go build -ldflags="-s -w"
try $ANDROID_ARM64_STRIP ck-client
try mv ck-client $DIR/main/jniLibs//arm64-v8a/libck-client.so

echo "Cross compile ckclient for x86"
try env CGO_ENABLED=1 CC=$ANDROID_X86_CC GOOS=android GOARCH=386 go build -ldflags="-s -w"
try $ANDROID_X86_STRIP ck-client
try mv ck-client $DIR/main/jniLibs/x86/libck-client.so
popd

echo "Success"