#!/bin/bash

set -eo pipefail

xcodebuild -workspace OTFMagicBox.xcworkspace \
            -scheme OTFMagicBox \
            -sdk iphoneos \
            -configuration AppStoreDistribution \
            -archivePath $PWD/build/OTFMagicBox.xcarchive \
            clean archive | xcpretty
