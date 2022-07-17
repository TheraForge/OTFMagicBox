#!/bin/bash

set -euo pipefail

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
echo "$PROVISIONING_PROFILE_DATA_DEBUG" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/OTFMagicBox_debug.mobileprovision
echo "$PROVISIONING_PROFILE_DATA_RELEASE" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/OTFMagicBox_release.mobileprovision
