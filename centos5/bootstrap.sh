#!/bin/bash

set -e
cd "$(dirname "$(readlink -f "$0")")"

set -x

if ! [[ -e RPM-GPG-KEY-CentOS-5 ]]; then
	wget "https://vault.centos.org/5.11/os/x86_64/RPM-GPG-KEY-CentOS-5"
fi

if ! [[ -d rootfs ]]; then
	mkdir rootfs
	dnf install --installroot=$PWD/rootfs --releasever=5 -y \
		--setopt=reposdir=/dev/null \
		--repofrompath=centos,https://vault.centos.org/5.11/os/x86_64/ \
		--setopt=centos.gpgkey=file://$PWD/RPM-GPG-KEY-CentOS-5 \
		--setopt=centos.gpgcheck=1 \
		@core

	# The rpmdb is built with the host rpm, so it will be too new to run with the rpm version inside the container.
	# We need to build a minimal rootfs again but this time running inside the container. For the same reason,
	# inside the bootstrap container, yum cannot resolve $releasever because it cannot query the rpmdb to find the
	# version of the "release" package, as defined by the `distroverpkg` in /etc/yum.conf

	sed -i 's/^mirrorlist/#mirrorlist/; s/^#baseurl/baseurl/; s/mirror.centos.org/localhost/; s/$releasever/5/' \
		rootfs/etc/yum.repos.d/CentOS-Base.repo
	podman run --network=host --rm --rootfs $PWD/rootfs yum install --installroot=/opt -y @core
fi

if ! podman images | grep -q centos5; then
	podman build --layers=false -t centos5:latest .
fi
