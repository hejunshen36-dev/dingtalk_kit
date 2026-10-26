#!/usr/bin/env bash
set -euo pipefail

# Run from any directory. FLUTTER_BIN may point to a specific Flutter SDK.
plugin_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_bin="${FLUTTER_BIN:-flutter}"
mode="${1:---publish}"
case "$mode" in
  --publish|--dry-run) ;;
  *) echo "Usage: $0 [--dry-run|--publish]" >&2; exit 64 ;;
esac
if [[ $# -gt 1 ]]; then
  echo "Expected at most one argument." >&2
  exit 64
fi
command -v "$flutter_bin" >/dev/null
command -v python3 >/dev/null

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/dingtalk-kit-publish.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
release_dir="$work_dir/package"
mkdir "$release_dir"
validation_log="$work_dir/pub-validation.log"

# Explicit inputs avoid publishing workspace data, credentials and stale builds.
# Include only the portable sample, without its local platform projects.
python3 - "$plugin_root" "$release_dir" <<'PY'
from pathlib import Path
import shutil
import sys

source, target = map(Path, sys.argv[1:])
directories = [
    'lib', 'test', 'android/src', 'android/libs', 'android/gradle',
    'ios/Classes', 'ios/Libraries', 'ohos/src',
]
files = [
    'pubspec.yaml', '.pubignore', 'LICENSE', 'CHANGELOG.md', 'README.md', 'README_CN.md',
    'SDK_VERSIONS.md',
    'android/build.gradle', 'android/settings.gradle', 'android/gradle.properties',
    'ios/dingtalk_kit.podspec', 'ohos/index.ets', 'ohos/oh-package.json5',
    'ohos/build-profile.json5', 'ohos/hvigorfile.ts',
    'example/README.md', 'example/lib/main.dart',
]
for name in directories:
    shutil.copytree(source / name, target / name,
                    ignore=shutil.ignore_patterns('.DS_Store', 'build', '.gradle'))
for name in files:
    destination = target / name
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source / name, destination)
PY

cd "$release_dir"
"$flutter_bin" pub get
"$flutter_bin" analyze --no-pub lib test example/lib
"$flutter_bin" test --no-pub test
validation_status=0
"$flutter_bin" pub publish --dry-run > "$validation_log" 2>&1 || validation_status=$?
cat "$validation_log"
python3 "$plugin_root/tool/check_pub_validation.py" "$validation_status" "$validation_log"

if [[ "$mode" == --publish ]]; then
  # Explicit invocation of this script authorizes upload after all checks pass.
  # Pub handles browser sign-in / uploader permissions; no tokens are stored here.
  "$flutter_bin" pub publish --force
fi
