#!/usr/bin/env bash

VERSION="trunk"
ARCH="ar71xx"
IMAGE_BUILDER="OpenWrt-ImageBuilder-$ARCH-generic.Linux-x86_64"
HTTP="http:/"
HTTPS="https:/"
OPENWRT_BASE_URL="downloads.openwrt.org/snapshots/$VERSION"
SRC="$HTTPS/$OPENWRT_BASE_URL/$ARCH/generic/$IMAGE_BUILDER.tar.bz2"
TARFILE="$IMAGE_BUILDER.tar.bz2"

# Get Dependencies (Ubuntu only for now)
sudo apt-get install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc

# Download Image Builder
if ! [ -e $TARFILE ]
then
    wget $SRC
fi
rm -rf /tmp/$IMAGE_BUILDER
tar xjfv $TARFILE -C /tmp
cp -Rv files/ /tmp/$IMAGE_BUILDER
pushd /tmp
cd $IMAGE_BUILDER

# Configure package repositiories
PACKAGE_BASE_URL="$HTTP/$OPENWRT_BASE_URL/$ARCH/generic/packages"
cat <<EOF > repositories.conf
src/gz chaos_calmer_base $PACKAGE_BASE_URL/base
src/gz chaos_calmer_luci $PACKAGE_BASE_URL/luci
src/gz chaos_calmer_management $PACKAGE_BASE_URL/management
src/gz chaos_calmer_packages $PACKAGE_BASE_URL/packages
src/gz chaos_calmer_routing $PACKAGE_BASE_URL/routing
src/gz chaos_calmer_telephony $PACKAGE_BASE_URL/telephony
## This is the local package repository, do not remove!
src imagebuilder file:packages
EOF

# Actually build the image, adding these packages
make image PROFILE=TLMR3040 PACKAGES="kmod-batman-adv batctl" FILES=files/

# Copy the generated image back to the current directory
popd
cp -f /tmp/$IMAGE_BUILDER/bin/$ARCH/*mr3040* images/
