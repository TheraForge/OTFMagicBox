#!/bin/sh
array=(`find ./OTFMagicBox/Samples.xcassets/ -name '*.png'`)
echo "const paths = \"${array[*]}\"" > ./images.js
open ./index.html
