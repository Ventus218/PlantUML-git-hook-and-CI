#!/bin/sh

# The following line is modified at realase time to automatically set the wrapper version
WRAPPER_VERSION="@WRAPPER_VERSION@"

# Simplest POSIX way to check if WRAPPER_VERSION is prefixed with a @
case $WRAPPER_VERSION in
@*)
    echo "Warning: you are running the template script, not the actual one" >&2
    exit 1
    ;;
esac

WRAPPER_MAJOR=${WRAPPER_VERSION%%.*}
BASE_URL="https://example.com" # change this to your actual host
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/puml_git_hook_and_ci"

# Searching for the config file going upward in the file tree
CONFIG_NAME="config.conf"
DIR=$(pwd)
CONFIG_FILE=""
while [ "$DIR" != "/" ]; do
    if [ -f "$DIR/$CONFIG_NAME" ]; then
        CONFIG_FILE="$DIR/$CONFIG_NAME"
        break
    fi
    DIR=$(dirname "$DIR")
done

if [ -z "$CONFIG_FILE" ]; then
    echo "Error: Config not found" >&2
    exit 1
fi

# shellcheck disable=SC1090
. "$CONFIG_FILE"

if [ -z "$VERSION" ]; then
    echo "Error: VERSION not set in $CONFIG_FILE" >&2
    exit 1
fi

CONFIG_MAJOR=${VERSION%%.*}

if [ "$CONFIG_MAJOR" -gt "$WRAPPER_MAJOR" ]; then
    echo "Wrapper v$WRAPPER_VERSION is too old for config version $VERSION" >&2
    echo "Please upgrade your wrapper to v$CONFIG_MAJOR.x or newer." >&2
    exit 1
elif [ "$CONFIG_MAJOR" -lt "$WRAPPER_MAJOR" ]; then
    echo "Wrapper v$WRAPPER_VERSION is newer than config version $VERSION"
    OLD_WRAPPER_URL="$BASE_URL/wrappers/v$CONFIG_MAJOR/wrapper.sh"
    OLD_WRAPPER_PATH="$CACHE_DIR/wrappers/v$CONFIG_MAJOR.sh"

    if [ ! -f "$OLD_WRAPPER_PATH" ]; then
        echo "Downloading old wrapper v$CONFIG_MAJOR..."
        mkdir -p "$(dirname "$OLD_WRAPPER_PATH")" || exit 1
        curl -fsSL "$OLD_WRAPPER_URL" -o "$OLD_WRAPPER_PATH" || {
            echo "Failed to download old wrapper." >&2
            exit 1
        }
        chmod +x "$OLD_WRAPPER_PATH" || exit 1
    fi

    echo "Delegating to old wrapper..."
    WRAP_DELEGATED=1 exec "$OLD_WRAPPER_PATH" "$@"
else
    echo "Running main script for version $VERSION..."
    MAIN_URL="$BASE_URL/main/v$VERSION/main.sh"
    MAIN_PATH="$CACHE_DIR/main/v$VERSION.sh"

    if [ ! -f "$MAIN_PATH" ]; then
        echo "Downloading main.sh v$VERSION..."
        mkdir -p "$(dirname "$MAIN_PATH")" || exit 1
        curl -fsSL "$MAIN_URL" -o "$MAIN_PATH" || {
            echo "Failed to download main script." >&2
            exit 1
        }
        chmod +x "$MAIN_PATH" || exit 1
    fi

    exec "$MAIN_PATH" "$@"
fi
