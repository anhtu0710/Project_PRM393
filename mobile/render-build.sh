#!/usr/bin/env bash
# Exit on error
set -o errexit

echo "=== Downloading Flutter SDK ==="
git clone https://github.com/flutter/flutter.git -b stable ./flutter
FLUTTER_PATH="`pwd`/flutter/bin"
export PATH="$PATH:$FLUTTER_PATH"

echo "=== Verifying Flutter installation ==="
flutter doctor -v

echo "=== Getting Flutter packages ==="
flutter pub get

echo "=== Building Flutter Web ==="
flutter build web --dart-define=API_URL=https://project-prm393-vtmx.onrender.com/api

echo "=== Build completed successfully ==="
