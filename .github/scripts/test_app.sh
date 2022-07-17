#!/bin/bash

set -eo pipefail

xcodebuild -workspace OTFMagicBox.xcworkspace \
            -scheme OTFMagicBox \
            clean test | xcpretty
