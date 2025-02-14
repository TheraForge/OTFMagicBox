#!/bin/bash

set -eo pipefail


latest_build=$(curl -s -H "Authorization: Bearer $TOKEN" "https://api.appstoreconnect.apple.com/v1/builds?filter\[app\]=$APP_ID&limit=1&sort=-uploadedDate" | jq -r '.data[0].attributes.version')
           echo "::set-output name=build_number::$latest_build"
