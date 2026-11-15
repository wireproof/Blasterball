#!/bin/sh
set -eu
cd "$(dirname "$0")"
exec xcodebuild -project Blasterball.xcodeproj -scheme Blasterball "$@"
