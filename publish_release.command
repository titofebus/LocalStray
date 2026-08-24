#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

VERSION="${1:-${LOCAL_STRAY_VERSION:-}}"
REPOSITORY="${LOCAL_STRAY_RELEASE_REPOSITORY:-}"
TAG="v$VERSION"
SPARKLE_ACCOUNT="${SPARKLE_ACCOUNT:-app.dech.localstray}"
SPARKLE_BIN="$PROJECT_DIR/.build/artifacts/sparkle/Sparkle/bin"
KEY_TOOL="$SPARKLE_BIN/generate_keys"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Usage: ./publish_release.command 0.1.0" >&2
    exit 1
fi
if [[ ! "$REPOSITORY" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    echo "Set LOCAL_STRAY_RELEASE_REPOSITORY to the canonical owner/repository." >&2
    exit 1
fi
ORIGIN_URL="$(git remote get-url origin)"
case "$ORIGIN_URL" in
    "https://github.com/$REPOSITORY" | \
    "https://github.com/$REPOSITORY.git" | \
    "git@github.com:$REPOSITORY" | \
    "git@github.com:$REPOSITORY.git" | \
    "ssh://git@github.com/$REPOSITORY" | \
    "ssh://git@github.com/$REPOSITORY.git") ;;
    *)
        echo "origin does not point to LOCAL_STRAY_RELEASE_REPOSITORY: $REPOSITORY" >&2
        exit 1
        ;;
esac
CURRENT_BRANCH="$(git branch --show-current)"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "Release publishing must run from main, not $CURRENT_BRANCH." >&2
    exit 1
fi
git fetch origin main
if ! git merge-base --is-ancestor origin/main HEAD; then
    echo "Local main must include the current origin/main before publishing." >&2
    exit 1
fi
export SPARKLE_FEED_URL="${SPARKLE_FEED_URL:-https://raw.githubusercontent.com/$REPOSITORY/main/appcast.xml}"
if [[ -z "${SPARKLE_PUBLIC_ED_KEY:-}" ]]; then
    export SPARKLE_PUBLIC_ED_KEY="$("$KEY_TOOL" --account "$SPARKLE_ACCOUNT" -p)"
fi
"$PROJECT_DIR/release_preflight.command" "$VERSION" --publish
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Tag already exists: $TAG" >&2
    exit 1
fi

export LOCAL_STRAY_VERSION="$VERSION"
export LOCAL_STRAY_BUILD_NUMBER="${LOCAL_STRAY_BUILD_NUMBER:-$(date -u +%Y%m%d%H%M)}"
"$PROJECT_DIR/release_app.command"

ARCHIVE="$PROJECT_DIR/LocalStray-v$VERSION-macOS.zip"
CHECKSUM="$ARCHIVE.sha256"
APPCAST_TOOL="$SPARKLE_BIN/generate_appcast"
if [ ! -x "$APPCAST_TOOL" ]; then
    echo "Resolve Sparkle before publishing: swift package resolve" >&2
    exit 1
fi

RELEASE_DIR="$(mktemp -d /private/tmp/localstray-release.XXXXXX)"
cleanup() {
    if [[ "$RELEASE_DIR" == /private/tmp/localstray-release.* ]]; then
        rm -rf "$RELEASE_DIR"
    fi
}
trap cleanup EXIT

update_appcast_channel_link() {
    local appcast_path="$1"
    local release_link="$2"
    local temporary_path
    temporary_path="$(mktemp "$RELEASE_DIR/appcast.XXXXXX")"

    if ! awk -v link="$release_link" '
        /<channel>/ { is_channel = 1 }
        is_channel && !did_update && /<link>/ {
            sub(/<link>[^<]*<\/link>/, "<link>" link "</link>")
            did_update = 1
        }
        { print }
        END { exit did_update ? 0 : 1 }
    ' "$appcast_path" > "$temporary_path"; then
        rm -f "$temporary_path"
        echo "Could not update the Local Stray appcast channel link." >&2
        exit 1
    fi
    mv "$temporary_path" "$appcast_path"
}

cp "$ARCHIVE" "$RELEASE_DIR/"
cp "$PROJECT_DIR/appcast.xml" "$RELEASE_DIR/appcast.xml"
update_appcast_channel_link \
    "$RELEASE_DIR/appcast.xml" \
    "https://github.com/$REPOSITORY/releases"

"$APPCAST_TOOL" \
    --account "$SPARKLE_ACCOUNT" \
    --download-url-prefix "https://github.com/$REPOSITORY/releases/download/$TAG/" \
    --link "https://github.com/$REPOSITORY/releases/tag/$TAG" \
    --maximum-versions 0 \
    --maximum-deltas 3 \
    -o "$RELEASE_DIR/appcast.xml" \
    "$RELEASE_DIR"

cp "$RELEASE_DIR/appcast.xml" "$PROJECT_DIR/appcast.xml"
git add appcast.xml
git commit -m "release: $TAG"
git tag -a "$TAG" -m "Local Stray $VERSION"
git push origin main
git push origin "$TAG"

gh release create "$TAG" "$ARCHIVE" "$CHECKSUM" \
    --repo "$REPOSITORY" \
    --title "Local Stray $VERSION" \
    --generate-notes \
    --verify-tag

echo "Published https://github.com/$REPOSITORY/releases/tag/$TAG"
