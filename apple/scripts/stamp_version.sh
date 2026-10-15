#!/bin/sh
# Build step of the Vijf, VijfWatch and VijfComplication targets. Writes the commit this build
# comes from into the built Info.plist (VijfCommit, with "+" for uncommitted changes, and
# VijfCommitDate) and sets the build number to the commit count, so the phone app, the watch app
# and the complication always match and the number goes up with every commit. The apps show it
# as "Version 3116643 · 15 Oct 2026" (VijfKit/AppVersion.swift).
set -e
plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
cd "$SRCROOT"
if commit=$(git rev-parse --short=7 HEAD 2>/dev/null); then
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then commit="$commit+"; fi
    date=$(git log -1 --format=%cs)
    count=$(git rev-list --count HEAD)
else
    commit=dev; date=""; count=1
fi
plutil -replace VijfCommit -string "$commit" "$plist"
plutil -replace VijfCommitDate -string "$date" "$plist"
plutil -replace CFBundleVersion -string "$count" "$plist"
