#!/usr/bin/env bash
set -euo pipefail

#------------------------------------------------------------------------------
# Versions
#------------------------------------------------------------------------------
readonly ZLIB_VERSION="1.3.1"
readonly OPENSSL_VERSION="3.4.0"
readonly OPENSSH_VERSION="V_9_9_P1"

#------------------------------------------------------------------------------
# Compiler and Directories
#------------------------------------------------------------------------------
export PATH=$PATH:$(echo /opt/musl*/bin)

readonly CC="x86_64-linux-musl-gcc" # Nota: en caso de usar compilar para 32 bits
export CC                           # se debe añadir la flag linux-generic32 en el
                                    # ./Configure de OpenSSL

readonly prefix="/opt/openssh"  # Final installation directory for OpenSSH
readonly top="$(pwd)"           # Root directory where everything is downloaded and built
readonly root="$top/root"       # Temporary installation directory
readonly build_dir="$top/build" # Build directory
readonly dist="$top/dist"       # Download directory

ls $prefix &>/dev/null || sudo mkdir -p $prefix

perm_dir() {
	sudo chown $USER -R $prefix
}

#------------------------------------------------------------------------------
# Zlib Configuration
#------------------------------------------------------------------------------
readonly ZLIB_DIR="zlib-${ZLIB_VERSION}"
readonly ZLIB_TGZ="${ZLIB_DIR}.tar.gz"
readonly ZLIB_URL="https://zlib.net/${ZLIB_TGZ}"
readonly ZLIB_CHECKFILE="lib/libz.a"

ZLIB_build() {
	./configure --prefix="$prefix" --static
	make -j"$(nproc)"
	sudo make install
	perm_dir
}

#------------------------------------------------------------------------------
# OpenSSL Configuration
#------------------------------------------------------------------------------
readonly OPENSSL_DIR="openssl-${OPENSSL_VERSION}"
readonly OPENSSL_TGZ="${OPENSSL_DIR}.tar.gz"
readonly OPENSSL_URL="https://www.openssl.org/source/${OPENSSL_TGZ}"
readonly OPENSSL_CHECKFILE="lib/libcrypto.a"

OPENSSL_build() {
	./Configure no-shared no-dso -static --prefix="$prefix" --openssldir="$prefix/ssl" # linux-generic32
	make -j"$(nproc)"
	sudo make install_sw
	perm_dir
}

#------------------------------------------------------------------------------
# OpenSSH Configuration
#------------------------------------------------------------------------------
readonly OPENSSH_DIR="openssh-portable-${OPENSSH_VERSION}"
readonly OPENSSH_TGZ="${OPENSSH_DIR}.tar.gz"
readonly OPENSSH_URL="https://github.com/openssh/openssh-portable/archive/refs/tags/${OPENSSH_VERSION}.tar.gz"
readonly OPENSSH_CHECKFILE="sbin/sshd"

OPENSSH_build() {
	autoreconf
	CFLAGS="-I$prefix/include" \
		LDFLAGS="-L$prefix/lib -L$prefix/lib64 -static" \
		./configure --prefix="$prefix" --exec-prefix="$prefix" --sysconfdir="$prefix/etc" \
		--with-privsep-user=nobody --with-ssl-dir="$prefix" --with-zlib="$prefix" \
		--with-default-path="$prefix/bin" --without-pam --disable-libsystemd
	make -j"$(nproc)"
	sudo make install
	perm_dir
}

#------------------------------------------------------------------------------
# User Prompt and Environment Setup
#------------------------------------------------------------------------------
read -r -p "We will be working in $top, things might get messy there. Press Ctrl+C to cancel now or Enter to continue: "

umask 0077 # Ensure secure file permissions

# Export flags for static compilation
export CPPFLAGS="-I$prefix/include -L. -fPIC -pthread"
export CFLAGS="$CPPFLAGS"
export LDFLAGS="-L$prefix/lib -L$prefix/lib64 -static"

#------------------------------------------------------------------------------
# Dependency Checks
#------------------------------------------------------------------------------
for cmd in autoreconf aclocal curl perl make gcc; do
	if ! command -v "$cmd" >/dev/null; then
		echo "Error: You need to install $cmd"
		exit 1
	fi
done

if [ ! -f /usr/include/linux/mman.h ]; then
	echo "Error: Linux kernel headers are missing"
	exit 1
fi

if ! echo "#include <stdio.h>" | gcc -E - -o /dev/null; then
	echo "Error: C library development files are missing"
	exit 1
fi

mkdir -p "$root" "$build_dir" "$dist"

#------------------------------------------------------------------------------
# Build Function
#------------------------------------------------------------------------------
build() {
	local name="$1"
	local version="$2"
	local dir="$3"
	local tar="$4"
	local url="$5"
	local checkfile="$6"
	local build_func="$7"
	local algo=""

	if [ ! -f "$prefix/$checkfile" ]; then
		echo "---- Building $name $version ----"
		rm -rf "$build_dir/$dir"
		if [ ! -f "$dist/$tar" ]; then
			curl --fail --retry 3 --compressed --user-agent "Mozilla/5.0" --output "${dist}/${tar}" --location "${url}"
		fi

		case $tar in
		*tgz | *tar.gz)
			algo="-xzf"
			;;
		*tar.xz)
			algo="-xJf"
			;;
		*)
			echo "Unsupported archive format: $tar"
			return 1
			;;
		esac

		tar -C "$build_dir" "$algo" "$dist/$tar"
		pushd "$build_dir/$dir" >/dev/null
		# Execute the corresponding build function
		$build_func
		popd >/dev/null
	else
		echo "---- $name $version is already built ----"
	fi
}

#------------------------------------------------------------------------------
# Build Steps
#------------------------------------------------------------------------------
build "ZLIB" "$ZLIB_VERSION" "$ZLIB_DIR" "$ZLIB_TGZ" "$ZLIB_URL" "$ZLIB_CHECKFILE" ZLIB_build
build "OpenSSL" "$OPENSSL_VERSION" "$OPENSSL_DIR" "$OPENSSL_TGZ" "$OPENSSL_URL" "$OPENSSL_CHECKFILE" OPENSSL_build
build "OpenSSH" "$OPENSSH_VERSION" "$OPENSSH_DIR" "$OPENSSH_TGZ" "$OPENSSH_URL" "$OPENSSH_CHECKFILE" OPENSSH_build

echo "Everything done. Statically linked OpenSSH binaries are in $prefix/sbin"
