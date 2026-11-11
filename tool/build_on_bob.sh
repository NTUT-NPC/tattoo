#!/usr/bin/env bash
set -euo pipefail

mode="${1:?Usage: bash tool/build_on_bob.sh <debug|profile|release> [--firebase]}"
case "$mode" in
  debug|profile|release) ;;
  *) printf 'Unsupported build mode: %s\n' "$mode" >&2; exit 1 ;;
esac
firebase="${2:-}"
if [[ $# -gt 2 || ( -n "$firebase" && "$firebase" != --firebase ) ]]; then
  printf 'Usage: bash tool/build_on_bob.sh <debug|profile|release> [--firebase]\n' >&2
  exit 1
fi

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
variant="$mode${firebase:+-firebase}"
output="$workspace/build/bob/$variant"
mkdir -p "$output"
# All profiles share one remote source tree and its incremental build cache.
lock="$workspace/build/bob/.lock"
if ! mkdir "$lock"; then
  printf 'Another Bob build is running. If it was interrupted, remove %s.\n' "$lock" >&2
  exit 1
fi
trap 'rmdir "$lock"' EXIT

workspace_key="$(printf '%s\n' "$(hostname):$workspace" | shasum -a 256)"
remote=".cache/tattoo-vscode/${workspace_key%% *}"
ssh_options=(-o BatchMode=yes -o ConnectTimeout=15)
export RSYNC_RSH='ssh -o BatchMode=yes -o ConnectTimeout=15'

printf 'Syncing working tree to bob:%s\n' "$remote"
ssh "${ssh_options[@]}" bob "mkdir -p '$remote'"
# Only Android build credentials cross the ignored-file boundary. Other secrets,
# local SDK paths, and generated build state remain on their original machines.
rsync --archive --compress --delete \
  --exclude='.git/' \
  --exclude='.gradle/' \
  --exclude='.kotlin/' \
  --exclude='local.properties' \
  --include='/android/key.properties' \
  --include='/android/app/keystore.jks' \
  --include='/android/app/src/staging/google-services.json' \
  --filter=':- .gitignore' \
  "$workspace/" "bob:$remote/"

printf 'Building staging %s on Bob\n' "$variant"
ssh "${ssh_options[@]}" bob "bash -s -- '$remote' '$mode' '$firebase'" <<'REMOTE'
set -euo pipefail
export GRADLE_USER_HOME="$HOME/.cache/tattoo-vscode/gradle"
cd "$1"
mode="$2"
firebase="$3"
# Noninteractive SSH does not source Bob's interactive mise activation.
export ANDROID_HOME=/usr/lib/android-sdk
export PATH="$ANDROID_HOME/platform-tools:$PATH"
mise trust
mise install flutter java
mise exec -- flutter pub get --enforce-lockfile
args=(build apk "--$mode" --flavor staging --no-pub --dart-define=cronetHttpNoPlay=true)
if [[ "$firebase" == --firebase ]]; then
  args+=(--dart-define=USE_FIREBASE=true)
fi
mise exec -- flutter "${args[@]}"
REMOTE

artifact="app-staging-$mode.apk"
printf 'Downloading %s\n' "$artifact"
rsync --archive --compress \
  "bob:$remote/build/app/outputs/flutter-apk/$artifact" "$output/$artifact"
printf 'Ready: %s\n' "$output/$artifact"
