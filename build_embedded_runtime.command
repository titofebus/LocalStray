#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
if [[ -n "${LOCAL_STRAY_RUNTIME_SOURCE:-}" ]]; then
    RUNTIME_SOURCE="$LOCAL_STRAY_RUNTIME_SOURCE"
elif [[ -x "$PROJECT_DIR/../LocalStrayRuntime/scripts/build_embedded_runtime.command" ]]; then
    RUNTIME_SOURCE="$PROJECT_DIR/../LocalStrayRuntime"
elif [[ -x "$PROJECT_DIR/../qwen-prime-runtime/scripts/build_embedded_runtime.command" ]]; then
    RUNTIME_SOURCE="$PROJECT_DIR/../qwen-prime-runtime"
else
    echo "LocalStrayRuntime mirror or compatible runtime checkout not found." >&2
    echo "Set LOCAL_STRAY_RUNTIME_SOURCE to the verified runtime checkout." >&2
    exit 1
fi
OUTPUT="${LOCAL_STRAY_RUNTIME_OUTPUT:-$PROJECT_DIR/.build/LocalStrayRuntime}"
BUILDER="$RUNTIME_SOURCE/scripts/build_embedded_runtime.command"

if [[ ! -x "$BUILDER" ]]; then
    echo "Runtime builder not found at $BUILDER" >&2
    echo "Set LOCAL_STRAY_RUNTIME_SOURCE to a verified runtime checkout." >&2
    exit 1
fi

"$BUILDER" "$OUTPUT"
echo "$OUTPUT"
