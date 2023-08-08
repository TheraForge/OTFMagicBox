#!/bin/sh
array=(`find ./OTFMagicBox/Assets.xcassets/Images/Assets -name '*'@3x.png'*'`)
echo "const paths = \"${array[*]}\"" > ./images.js
open ./index.html
