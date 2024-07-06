#!/usr/bin/env bash

set -euxo pipefail

function getHostTag() {
	# Copyright (C) 2022 The Android Open Source Project
	#
	# Licensed under the Apache License, Version 2.0 (the "License");
	# you may not use this file except in compliance with the License.
	# You may obtain a copy of the License at
	#
	#      http://www.apache.org/licenses/LICENSE-2.0
	#
	# Unless required by applicable law or agreed to in writing, software
	# distributed under the License is distributed on an "AS IS" BASIS,
	# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	# See the License for the specific language governing permissions and
	# limitations under the License.
	#
	# From NDK/build/tools/ndk_bin_common.sh

	HOST_OS=$(uname -s)
	case $HOST_OS in
	  Darwin) HOST_OS=darwin;;
	  Linux) HOST_OS=linux;;
	  FreeBsd) HOST_OS=freebsd;;
	  CYGWIN*|*_NT-*) HOST_OS=cygwin;;
	  *) echo "ERROR: Unknown host operating system: $HOST_OS"
	     exit 1
	esac

	HOST_ARCH=$(uname -m)
	case $HOST_ARCH in
	  arm64) HOST_ARCH=arm64;;
	  i?86) HOST_ARCH=x86;;
	  x86_64|amd64) HOST_ARCH=x86_64;;
	  *) echo "ERROR: Unknown host CPU architecture: $HOST_ARCH"
	     exit 1
	esac

	HOST_TAG=$HOST_OS-$HOST_ARCH

	if [ $HOST_TAG = darwin-arm64 ]; then
	  # The NDK ships universal arm64+x86_64 binaries in the darwin-x86_64
	  # directory.
	  HOST_TAG=darwin-x86_64
	fi
}

#Copyright (C) 2017 by Max Lv <max.c.lv@gmail.com>
#Copyright (C) 2017 by Mygod Studio <contact-shadowsocks-android@mygod.be>
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

pushd ../..
ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$(./gradlew -q printNDKPath)}"
popd

while [ ! -d "$ANDROID_NDK_HOME" ]; do
  echo "Path to ndk-bundle not found"
  exit -1
done

getHostTag
MIN_API=21
ANDROID_PREBUILT_TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG"

ANDROID_ARM_CC="$ANDROID_PREBUILT_TOOLCHAIN/bin/armv7a-linux-androideabi${MIN_API}-clang"

ANDROID_ARM64_CC="$ANDROID_PREBUILT_TOOLCHAIN/bin/aarch64-linux-android21-clang"

ANDROID_X86_CC="$ANDROID_PREBUILT_TOOLCHAIN/bin/i686-linux-android${MIN_API}-clang"

ANDROID_X86_64_CC="$ANDROID_PREBUILT_TOOLCHAIN/bin/x86_64-linux-android${MIN_API}-clang"

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$SRC_DIR/main/jniLibs/armeabi-v7a" "$SRC_DIR/main/jniLibs/x86" "$SRC_DIR/main/jniLibs/arm64-v8a" "$SRC_DIR/main/jniLibs/x86_64"

cd Cloak
go get ./...
cd cmd/ck-client

echo "Cross compiling ckclient for arm"
env CGO_ENABLED=1 CC="$ANDROID_ARM_CC" GOOS=android GOARCH=arm GOARM=7 go build -ldflags="-s -w"
mv ck-client "$SRC_DIR/main/jniLibs/armeabi-v7a/libck-client.so"

echo "Cross compiling ckclient for arm64"
env CGO_ENABLED=1 CC="$ANDROID_ARM64_CC" GOOS=android GOARCH=arm64 go build -ldflags="-s -w"
mv ck-client "$SRC_DIR/main/jniLibs/arm64-v8a/libck-client.so"

echo "Cross compiling ckclient for x86"
env CGO_ENABLED=1 CC="$ANDROID_X86_CC" GOOS=android GOARCH=386 go build -ldflags="-s -w"
mv ck-client "$SRC_DIR/main/jniLibs/x86/libck-client.so"

echo "Cross compiling ckclient for x86_64"
env CGO_ENABLED=1 CC="$ANDROID_X86_64_CC" GOOS=android GOARCH=amd64 go build -ldflags="-s -w"
mv ck-client "$SRC_DIR/main/jniLibs/x86_64/libck-client.so"

echo "Success"
