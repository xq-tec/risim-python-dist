#!/bin/bash
set -euxo pipefail

VERSION=3.14
TARGET=x86_64_v2-unknown-linux-gnu
VARIANT=lto

REPO_ROOT=$(realpath $(dirname $0))
BUILD_DIR=$REPO_ROOT/python-build-standalone
UNPACK_DIR=$BUILD_DIR/dist/$VARIANT
LIB_DIR=$UNPACK_DIR/python/install/lib

FULL_DIST_ARCHIVE=$BUILD_DIR/dist/cpython-${VERSION}*-$TARGET-$VARIANT*.tar.zst
# Only run the Python build if the distribution archive does not exist
if [ ! -f $FULL_DIST_ARCHIVE ] ; then
  rm -rf $BUILD_DIR/dist
  cd $BUILD_DIR
  uv run --no-dev build.py --target-triple $TARGET --python cpython-$VERSION --options $VARIANT
fi
rm -rf $UNPACK_DIR
mkdir -p $UNPACK_DIR
tar -C $UNPACK_DIR -xf $FULL_DIST_ARCHIVE

# Install VUnit and its dependencies

cd $UNPACK_DIR/python/install
bin/pip3.14 install $REPO_ROOT/vunit

# Remove unnecessary files and directories

find -name __pycache__ -exec rm -rf {} +
find -name '*.dist-info' -exec rm -rf {} +

cd $LIB_DIR
strip libpython${VERSION}.so.1.0
# In lib/: keep only libpython${VERSION}.so.1.0 and python${VERSION}/
find . -mindepth 1 -maxdepth 1 \
  ! -name libpython${VERSION}.so.1.0 \
  ! -name python${VERSION} \
  -exec rm -rf {} +

cd $LIB_DIR/python${VERSION}
rm -rf \
  config-${VERSION}-x86_64-linux-gnu \
  test \
  lib-dynload \
  idlelib \
  ensurepip

cd $LIB_DIR/python${VERSION}/site-packages
rm -rf pip/ "pip-*.dist-info/"

# Zip the distribution
cd $UNPACK_DIR/python/install
tar -czf python-linux.tar.gz lib/
mv python-linux.tar.gz $REPO_ROOT/

# Build the Windows distribution

cd $REPO_ROOT
rm -rf python-windows python-windows.zip
unzip -d python-windows windows/python-${VERSION}*-embed-amd64.zip
cd $LIB_DIR/python${VERSION}/site-packages
zip -r $REPO_ROOT/python-windows/python${VERSION//./} *
cd $REPO_ROOT/python-windows
zip -r $REPO_ROOT/python-windows.zip .
