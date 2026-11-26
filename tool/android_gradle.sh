#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
android_jdk="${CLASSLIFT_JAVA_HOME:-${JAVA_HOME:-}}"
if [[ -z "$android_jdk" ]]; then
  if [[ -d /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home ]]; then
    android_jdk=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
  elif [[ "$(uname)" == Darwin ]]; then
    android_jdk="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  fi
fi
if [[ ! -x "$android_jdk/bin/java" ]]; then
  echo 'Configurá CLASSLIFT_JAVA_HOME con un JDK 17 o 21.' >&2
  exit 1
fi
java_version="$("$android_jdk/bin/java" -version 2>&1 | head -1)"
if [[ ! "$java_version" =~ \"(17|21)\. ]]; then
  echo 'La compilación de ClassLift requiere JDK 17 o 21. Configurá CLASSLIFT_JAVA_HOME.' >&2
  exit 1
fi

cd "$project_root"
flutter pub get
cd android
export JAVA_HOME="$android_jdk"
export PATH="$JAVA_HOME/bin:$PATH"
exec ./gradlew --no-daemon --max-workers=2 "$@"
