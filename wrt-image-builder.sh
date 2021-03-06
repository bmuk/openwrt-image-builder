#!/usr/bin/env bash

VERSION="trunk"
ARCH="ar71xx"
IMAGE_BUILDER="OpenWrt-ImageBuilder-$ARCH-generic.Linux-x86_64"
HTTP="http:/"
HTTPS="https:/"
OPENWRT_BASE_URL="downloads.openwrt.org/snapshots/$VERSION"
SRC="$HTTPS/$OPENWRT_BASE_URL/$ARCH/generic/$IMAGE_BUILDER.tar.bz2"
TARFILE="$IMAGE_BUILDER.tar.bz2"

if [ -e /etc/redhat-release ]
then
  # Get Dependencies (Fedora)
  sudo dnf install -y subversion make automake gcc gcc-c++ kernel-devel ncurses-devel zlib-devel gawk git ccache gettext openssl-devel libxslt
else
  # Get Dependencies (Ubuntu only for now)
  sudo apt-get install -y subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc
fi

# Download Image Builder
if ! [ -e $TARFILE ]
then
    echo "Tarfile has not been fetched; fetching..."
    wget $SRC
fi
rm -rf /tmp/$IMAGE_BUILDER
echo "Untarring image builder..."
tar xjf $TARFILE -C /tmp
echo "Moving into build directory"
pushd /tmp
cd $IMAGE_BUILDER
echo "Creating configuration directory"
mkdir -p files/etc

# Get node specific settings
TYPE=0
while [ $TYPE -ne 1 ] && [ $TYPE -ne 2 ]
do
    echo "AP (1) or Gateway (2): "
    read TYPE
done
echo "Enter a hostname for this node: "
read HOSTNAME

if [ $TYPE -eq 1 ]
then
    git clone https://github.com/bmuk/batman-ap files/etc/config
else
    git clone https://github.com/bmuk/batman-gateway files/etc/config
    echo "Provide an unused IP address for the gateway: "
    read IP
    sed -i 's/10.0.0.1/$IP' files/etc/config/network
fi

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

cat <<EOF > files/etc/config/system
config 'system'
        option 'hostname' $HOSTNAME
EOF

# Actually build the image, adding these packages
make image PROFILE=TLMR3040 PACKAGES="kmod-batman-adv batctl alfred" FILES=files/

# Copy the generated image back to the current directory
popd
cp -f /tmp/$IMAGE_BUILDER/bin/$ARCH/*mr3040* images/
