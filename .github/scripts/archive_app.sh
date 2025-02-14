#!/bin/bash

set -eo pipefail

xcodebuild -workspace OTFMagicBox.xcworkspace \
            -scheme OTFMagicBox \
            -configuration AppStoreDistribution \
            -archivePath $PWD/build/OTFMagicBox.xcarchive \
            clean archive

