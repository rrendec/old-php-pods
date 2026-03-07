#!/bin/bash

set -e
cd "$(dirname "$(readlink -f "$0")")"

RELEASEVER=11
BASEURL="https://archives.fedoraproject.org/pub/archive/fedora/linux/releases/$RELEASEVER/Everything/x86_64/os"

set -x

if ! [[ -e RPM-GPG-KEY-fedora ]]; then
	wget "$BASEURL/RPM-GPG-KEY-fedora"
fi

if ! [[ -d rootfs ]]; then
	mkdir rootfs
	dnf install --installroot=$PWD/rootfs --releasever=$RELEASEVER -y \
		--setopt=reposdir=/dev/null \
		--repofrompath=fedora,$BASEURL \
		--setopt=fedora.gpgkey=file://$PWD/RPM-GPG-KEY-fedora \
		--setopt=fedora.gpgcheck=1 \
		@core

	# The rpmdb is built with the host rpm, so it will be too new to run with the rpm version inside the container.
	# We need to build a minimal rootfs again but this time running inside the container. For the same reason,
	# inside the bootstrap container, yum cannot resolve $releasever because it cannot query the rpmdb to find the
	# version of the "release" package, as defined by the `distroverpkg` in /etc/yum.conf

	sed -i 's/^mirrorlist/#mirrorlist/; s/^#baseurl/baseurl/; s/download.fedoraproject.org\/pub/localhost/' \
		rootfs/etc/yum.repos.d/fedora.repo rootfs/etc/yum.repos.d/fedora-updates.repo

	# Broken yum version: it doesn't take --releasever on the command line, nor does it know about /etc/yum/vars
	# (see how releasever is set up in /usr/lib/python2.6/site-packages/yum/config.py). If the distroverpkg package
	# is not installed, it literally sets releasever to '$releasever', which is silly. And it looks for the package
	# in the installroot, which is of course empty.
	sed -i 's/\$releasever/'$RELEASEVER'/' \
		rootfs/etc/yum.repos.d/fedora.repo rootfs/etc/yum.repos.d/fedora-updates.repo

	podman run --network=host --rm --rootfs $PWD/rootfs yum install --installroot=/opt -y @core
fi

if ! podman images | grep -q fedora$RELEASEVER; then
	podman build --layers=false -t fedora$RELEASEVER:latest .
fi
