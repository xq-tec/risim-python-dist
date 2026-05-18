#!/bin/bash
set -euo pipefail

VERSION=3.14
TARGET=x86_64_v2-unknown-linux-gnu
VARIANT=lto

REPO_ROOT=$(realpath $(dirname $0))
BUILD_DIR=$REPO_ROOT/python-build-standalone
UNPACK_DIR=$BUILD_DIR/dist/$VARIANT

rm -rf $BUILD_DIR/dist/*
cd $BUILD_DIR
uv run --no-dev build.py --target-triple $TARGET --python cpython-$VERSION --options $VARIANT
mkdir -p $UNPACK_DIR
tar -C $UNPACK_DIR -xf $BUILD_DIR/dist/cpython-$VERSION*-$TARGET-$VARIANT*.tar.zst

# Remove unnecessary files and directories

cd $UNPACK_DIR/python/install
rm -rf bin/ include/ share/

cd $UNPACK_DIR/python/install/lib
strip libpython$VERSION.so.1.0
# In lib/: keep only libpython${VERSION}.so.1.0 and python${VERSION}/
find . -mindepth 1 -maxdepth 1 \
  ! -name libpython${VERSION}.so.1.0 \
  ! -name python${VERSION} \
  -exec rm -rf {} +

cd $UNPACK_DIR/python/install/lib/python${VERSION}
rm -rf \
  config-${VERSION}-x86_64-linux-gnu \
  test \
  lib-dynload \
  idlelib \
  ensurepip

cd $UNPACK_DIR/python/install/lib/python${VERSION}/site-packages
rm -rf pip/ "pip-*.dist-info/"

# Zip the distribution
cd $UNPACK_DIR/python/install
zip -r python-linux.zip lib/
mv python-linux.zip $REPO_ROOT/
