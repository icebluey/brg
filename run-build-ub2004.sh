#!/bin/bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
TZ='UTC'; export TZ
umask 022
set -e
cd "$(dirname "$0")"
systemctl start docker
sleep 5
echo
cat /proc/cpuinfo
echo
if [ "$(cat /proc/cpuinfo | grep -i '^processor' | wc -l)" -gt 1 ]; then
    docker run --cpus="$(cat /proc/cpuinfo | grep -i '^processor' | wc -l).0" --rm --name ub2004 -itd ubuntu:20.04 bash
else
    docker run --rm --name ub2004 -itd ubuntu:20.04 bash
fi
sleep 2
docker exec ub2004 apt update -y -qqq
docker exec ub2004 apt install -y -qqq wget bash openssl gcc g++ cmake m4 pkg-config libc6-dev git curl
docker exec ub2004 apt install -y -qqq coreutils binutils findutils util-linux sed gawk tar xz-utils gzip bzip2
docker exec ub2004 /bin/bash -c 'ln -svf bash /bin/sh'
docker exec ub2004 /bin/bash -c 'ln -svf ../usr/share/zoneinfo/UTC /etc/localtime'
docker exec ub2004 /bin/bash -c 'DEBIAN_FRONTEND=noninteractive apt install -y -qqq tzdata'
docker exec ub2004 /bin/bash -c 'dpkg-reconfigure --frontend noninteractive tzdata'
docker exec ub2004 apt upgrade -fy -qqq
docker exec ub2004 /bin/bash -c 'rm -fr /tmp/*'
docker cp ub2004 ub2004:/home/
docker exec ub2004 /bin/bash /home/ub2004/brg.sh
mkdir -p /tmp/_output_assets
docker cp ub2004:/tmp/_output /tmp/_output_assets/

exit
