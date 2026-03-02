#!/usr/bin/env bash
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date +"%Y-%m-%d %H:%M:%S %Z")

cat > lib/build_info.dart << EOF
/// Build information - auto-generated at build time
class BuildInfo {
  static const String version = '1.0.0+1';
  static const String commit = '$COMMIT';
  static const String buildTime = '$BUILD_TIME';
}
EOF
