#!/bin/bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
CC=gcc
export CC
CXX=g++
export CXX
/sbin/ldconfig

set -euo pipefail

_strip_files() {
    if [[ "$(pwd)" = '/' ]]; then
        echo
        printf '\e[01;31m%s\e[m\n' "Current dir is '/'"
        printf '\e[01;31m%s\e[m\n' "quit"
        echo
        exit 1
    else
        rm -fr lib64
        rm -fr lib
        chown -R root:root ./
    fi
    find usr/ -type f -iname '*.la' -delete
    if [[ -d usr/share/man ]]; then
        find -L usr/share/man/ -type l -exec rm -f '{}' \;
        find usr/share/man/ -type f -iname '*.[1-9]' -exec gzip -f -9 '{}' \;
        find -L usr/share/man/ -type l | while read file; do ln -svf "$(readlink -s "${file}").gz" "${file}.gz" ; done
        find -L usr/share/man/ -type l -exec rm -f '{}' \;
    fi
    if [[ -d usr/lib/x86_64-linux-gnu ]]; then
        find usr/lib/x86_64-linux-gnu/ -type f \( -iname '*.so' -or -iname '*.so.*' \) | xargs --no-run-if-empty -I '{}' chmod 0755 '{}'
        find usr/lib/x86_64-linux-gnu/ -iname 'lib*.so*' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[[:space:]]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
        find usr/lib/x86_64-linux-gnu/ -iname '*.so' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[[:space:]]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
    fi
    if [[ -d usr/lib64 ]]; then
        find usr/lib64/ -type f \( -iname '*.so' -or -iname '*.so.*' \) | xargs --no-run-if-empty -I '{}' chmod 0755 '{}'
        find usr/lib64/ -iname 'lib*.so*' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[[:space:]]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
        find usr/lib64/ -iname '*.so' -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[[:space:]]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
    fi
    if [[ -d usr/sbin ]]; then
        find usr/sbin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[[:space:]]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
    fi
    if [[ -d usr/bin ]]; then
        find usr/bin/ -type f -exec file '{}' \; | sed -n -e 's/^\(.*\):[[:space:]]*ELF.*, not stripped.*/\1/p' | xargs --no-run-if-empty -I '{}' strip '{}'
    fi
    echo
}

_install_rust() {
    set -e
    _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _rust_ver="$(wget -qO- 'https://forge.rust-lang.org/infra/other-installation-methods.html#standalone' | grep -i '\.tar\.xz' | sed 's/"/\n/g' | grep -i 'https://.*xz$' | grep -ivE 'beta|nightly|src' | grep -i 'x86_64-unknown-linux-gnu' | sort -V | uniq | tail -n 1 | sed -e 's|.*rust-||g' -e 's|-x86.*||g')"
    wget -c -t 0 -T 9 "https://static.rust-lang.org/dist/rust-${_rust_ver}-x86_64-unknown-linux-gnu.tar.xz"
    tar -xof *.tar*
    sleep 1
    rm -fr *.tar*
    cd rust-*
    rm -fr /usr/local/rust
    #bash install.sh --prefix=/usr/local/rust
    bash install.sh --prefix=/usr/local
    sleep 1
    cd /tmp
    rm -fr "${_tmp_dir}"
    #export RUST_HOME="/usr/local/rust"
    #export RUST_HOME="/usr/local"
    #export PATH=$RUST_HOME/bin:$PATH
    #export LD_LIBRARY_PATH=$RUST_HOME/lib:$LD_LIBRARY_PATH
    export CARGO_HOME='.cargo'
    echo
    cargo --version
    echo
}

_build_pcre2() {
    /sbin/ldconfig
    set -euo pipefail
    local _tmp_dir="$(mktemp -d)"
    cd "${_tmp_dir}"
    _pcre2_ver="$(wget -qO- 'https://github.com/PCRE2Project/pcre2/releases' | grep -i 'pcre2-[1-9]' | sed 's|"|\n|g' | grep -i '^/PCRE2Project/pcre2/tree' | sed 's|.*/pcre2-||g' | sed 's|\.tar.*||g' | grep -ivE 'alpha|beta|rc' | sort -V | uniq | tail -n 1)"
    wget -c -t 9 -T 9 "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${_pcre2_ver}/pcre2-${_pcre2_ver}.tar.bz2"
    tar -xof pcre2-${_pcre2_ver}.tar*
    rm -f pcre2-*.tar*
    cd pcre2-*
    ./configure \
    --build=x86_64-linux-gnu --host=x86_64-linux-gnu \
    --enable-shared --enable-static \
    --enable-pcre2-8 --enable-pcre2-16 --enable-pcre2-32 \
    --enable-jit --enable-unicode \
    --prefix=/usr --libdir=/usr/lib/x86_64-linux-gnu --includedir=/usr/include --sysconfdir=/etc
    sed 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' -i libtool
    make -j$(nproc --all) all
    rm -fr /tmp/pcre2
    make install DESTDIR=/tmp/pcre2
    cd /tmp/pcre2
    rm -fr usr/share/doc/pcre2/html
    _strip_files
    /bin/cp -afr * /
    cd /tmp
    rm -fr "${_tmp_dir}"
    rm -fr /tmp/pcre2
    /sbin/ldconfig
}
_build_pcre2

############################################################################
_install_rust
export CARGO_HOME='.cargo'
############################################################################
/sbin/ldconfig
_tmp_dir="$(mktemp -d)"
cd "${_tmp_dir}"
# /BurntSushi/ripgrep/archive/refs/tags/15.1.0.tar.gz
#_filepath="$(wget -qO- 'https://github.com/BurntSushi/ripgrep/releases' | grep -i 'archive/refs/tags/.*tar.*' | sed 's|"|\n|g' | grep -i 'archive/refs/tags/.*tar.*' | sort -V | tail -n 1)"
# https://github.com/BurntSushi/ripgrep/archive/refs/tags/15.1.0.tar.gz
#wget -c -t 9 -T 9 "https://github.com${_filepath}"
#tar -xof *.tar*
#sleep 1
#rm -f *.tar*
#cd ripgrep*

git clone https://github.com/BurntSushi/ripgrep.git
cd ripgrep
git tag | sort -V
git tag | grep '^[0-9]' | sort -V | tail -n 1
git checkout "$(git tag | grep '^[0-9]' | sort -V | tail -n 1)"

export PCRE2_SYS_STATIC=1
cargo check
cargo build --release --features 'pcre2'
cargo test --all
sleep 1
strip target/release/rg
sleep 1
./target/release/rg --version
rm -fr /tmp/_output
mkdir /tmp/_output
cp -a target/release/rg /tmp/_output/
./target/release/rg --version 2>&1 | head -n 1 | awk '{print $2}' > /tmp/_output/version.txt
cd /tmp/_output
tar -Jcf rg-ub2204.tar.xz rg
sleep 1
sha256sum -b rg-ub2204.tar.xz > rg-ub2204.tar.xz.sha256
cat rg-ub2204.tar.xz.sha256
rm -f rg

cd /tmp
rm -fr "${_tmp_dir}"
echo
echo ' build rg ub2204 done'
echo
exit
