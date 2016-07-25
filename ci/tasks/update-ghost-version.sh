#!/bin/bash

set -e -x

tar xfz ghost/source.tar.gz
# creates TryGhost-Ghost-XXXX folder

git clone ghost-for-cf ghost-updated

rm -rf ghost-updated/core ghost-updated/index.js ghost-updated/package.json ghost-updated/shrinkwrap.json

cp -r TryGhost-Ghost-*/core ghost-updated/
cp -r TryGhost-Ghost-*/index.js ghost-updated/
cp -r TryGhost-Ghost-*/package.json ghost-updated/

cd ghost-updated

npm install --save
npm shrinkwrap
