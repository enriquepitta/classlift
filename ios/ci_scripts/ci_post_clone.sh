#!/bin/sh
set -eu

# Match the Flutter SDK used to build the app locally.
FLUTTER_REVISION=c9306d5b2e
git clone --filter=blob:none https://github.com/flutter/flutter.git "$HOME/flutter"
git -C "$HOME/flutter" checkout "$FLUTTER_REVISION"
export PATH="$HOME/flutter/bin:$PATH"

cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter precache --ios
flutter pub get
flutter build ios --release --config-only --no-codesign --build-number="${CI_BUILD_NUMBER:-1}"
cd ios
pod install
