#!/usr/bin/env bash
# Build script - compiles Flutter web app

set -e

echo "Building Flutter web app..."
flutter build web --release

echo "Build complete. Output in build/web/"
