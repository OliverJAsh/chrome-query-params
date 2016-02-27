#!/bin/bash

echo "Bump version in manifest"
read

rm -rf upload upload.zip
mkdir upload

cp -f manifest.json popup.html boot.js elm.js upload

pushd upload
    zip -r upload.zip .
    mv upload.zip ..
popd
