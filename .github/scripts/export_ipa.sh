#!/bin/bash

set -eo pipefail

xcodebuild -archivePath $PWD/build/OTFMagicBox.xcarchive \
            -exportOptionsPlist OTFMagicBox/exportOptions.plist \
            -exportPath $PWD/build \
            -allowProvisioningUpdates \
            -exportArchive | xcpretty
