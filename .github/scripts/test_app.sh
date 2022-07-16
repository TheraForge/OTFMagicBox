#!/bin/bash

set -eo pipefail

xcodebuild -workspace OTFMagicBox.xcworkspace \
            -scheme OTFMagicBox \
            -destination platform=iOS\ Simulator,OS=15.5,name=iPhone\ 13 \
            clean test | xcpretty
