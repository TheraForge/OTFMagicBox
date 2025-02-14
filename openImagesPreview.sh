#!/bin/sh
array=(`find ./Images.xcassets/Assets -name '*'@2x.png'*'`)
echo "const paths = \"${array[*]}\"" > ./images.js
open ./index.html
