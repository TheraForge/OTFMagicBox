#!/bin/bash

set -euo pipefail


mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
        echo "$PROVISIONING_PROFILE_WATCH_RELEASE" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/OTFMagicBoxWatchProv.mobileprovision
