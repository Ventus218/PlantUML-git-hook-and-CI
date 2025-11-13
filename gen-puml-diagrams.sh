#!/bin/sh

# Redirect output to stderr.
exec 1>&2

set -eu

DEFAULT_CONFIG_FILE_NAME="gen-puml-diagrams-config.sh"

usage() {
    BASENAME=$(basename "$0")
    cat <<EOF
Usage:
    1) $BASENAME [-h] [-p] [<input-dir> <output-dir>]
    2) $BASENAME [-h] [-p] [-c <config-file>]

Description:
    Generate PlantUML diagrams from sources contained in <input-dir> into
    <output-dir> mirroring the directory structure.
    <input-dir> and <output-dir> are directly passed to PlantUML so if you want to
    understand better how they work you should read the PlantUML CLI documentation.

Configuration file:
    When used in form number 2 the script will source a configuration file to get
    the input and output directories.
    The configuration file can be specified by the -c option, otherwise a file
    named "$DEFAULT_CONFIG_FILE_NAME" will be recursively searched upward from
    this script location.
    Paths defined inside the configuration file will be interpreted as relative
    from the configuration file location.
    The configuration file content should be something like the following:

        INPUT_DIR=diagrams/src
        OUTPUT_DIR=diagrams/gen
  
Options:
    -h
        Show this message and exit

    -p  
        (pre-commit) The script will generate diagrams reflecting only the staged
        changes and adding the generated diagrams to the stage. It is meant to be
        run as a pre-commit git hook

    -c  <config-file> 
        Path to the configuration file

Examples:
    $BASENAME diagrams/src diagrams/gen
    $BASENAME -p diagrams/src diagrams/gen
    $BASENAME 
    $BASENAME -p -c config.sh
EOF
}

PRE_COMMIT=false
CONFIG_FILE=""
INPUT_DIR=""
OUTPUT_DIR=""

while getopts ':hpc:' opt; do
    case $opt in
    h)
        usage
        exit
        ;;
    p) PRE_COMMIT=true ;;
    c) CONFIG_FILE="$OPTARG" ;;
    :)
        echo "Error: Option -$OPTARG requires an argument." >&2
        usage
        exit 1
        ;;
    \?)
        echo "Error: Invalid option -$OPTARG" >&2
        usage
        exit 1
        ;;
    esac
done
shift "$((OPTIND - 1))"

if [ $# -eq 2 ]; then
    if [ -z "$CONFIG_FILE" ]; then
        INPUT_DIR="$1"
        OUTPUT_DIR="$2"
    else
        usage
        exit 1
    fi
else
    # Searching for the config file going upward in the file tree
    # if it is not already specified
    DIR=$(
        cd "$(dirname "$0")"
        pwd
    )
    while [ -z "$CONFIG_FILE" ] && [ "$DIR" != "/" ]; do
        FILE="$DIR/$DEFAULT_CONFIG_FILE_NAME"
        if [ -f "$FILE" ]; then
            CONFIG_FILE="$FILE"
            break
        fi
        DIR=$(dirname "$DIR")
    done
    unset DIR
    unset FILE

    if [ ! -r "$CONFIG_FILE" ]; then
        echo "Error: configuration file not found or not readable" >&2
        exit 1
    fi

    echo "Sourcing configuration file" >&2
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"

    # Paths inside the configuration file may be relative and should be interpreted
    # as relative to the configuration file, not the current working directory
    CONFIG_DIR=$(dirname "$CONFIG_FILE")
    CWD=$(pwd)
    cd "$CONFIG_DIR"
    if [ -d "$INPUT_DIR" ]; then # Don't need an else block since i'll check this again later
        INPUT_DIR=$(
            cd "$INPUT_DIR"
            pwd
        )
    fi
    if [ -d "$OUTPUT_DIR" ]; then # Don't need an else block since i'll check this again later
        OUTPUT_DIR=$(
            cd "$OUTPUT_DIR"
            pwd
        )
    fi
    cd "$CWD"
fi

check_input_or_output_dir() {
    if [ ! -d "$1" ]; then
        echo "Error: invalid $2 directory \"$1\"" >&2
        usage
        exit 1
    fi
}
check_input_or_output_dir "$INPUT_DIR" "input"
check_input_or_output_dir "$OUTPUT_DIR" "output"

if ! command -v docker >/dev/null 2>&1; then
    echo "Error: Docker is required for generating PlantUML diagrams" >&2
    exit 1
fi

# --------- END OF VALIDATION ---------

# If PRE_COMMIT is set we check if there are staged changes
if ! $PRE_COMMIT || ! git diff --quiet --staged -- "$INPUT_DIR" "$OUTPUT_DIR"; then

    # Pulling the image before doing anything in so that we do nothing if the pull fails
    echo "Pulling plantuml Docker image..."
    docker pull plantuml/plantuml:latest

    if $PRE_COMMIT; then
        # Stashing everything that is not staged (so we can build images only of what will be committed)
        git stash push --quiet --keep-index --include-untracked
        # Now we have just the staged changes
    fi

    # Copying the sources folder into a temporary one
    TEMP_DIR=$(mktemp -d)
    TEMP_SRC="$TEMP_DIR/src"
    mkdir "$TEMP_SRC"
    TEMP_GEN="$TEMP_DIR/gen"
    mkdir "$TEMP_GEN"
    cp -r "$INPUT_DIR/"* "$TEMP_SRC" || true # TODO: should we suppress stderr?

    if $PRE_COMMIT; then
        # Resetting the repo in order to avoid merge conflicts when popping the stash
        git reset --quiet --hard
        # Here we pop while also restoring the index because from now on we can work on the temp folder
        git stash pop --quiet --index
    fi

    echo "Generating UML diagrams"
    if docker run --rm -v "/${TEMP_DIR}":/data plantuml/plantuml:latest -failfast2 -o ../gen //data/src; then
        # Substituting the generated folder with the new one
        rm -rf "$OUTPUT_DIR"
        cp -r "$TEMP_GEN" "$OUTPUT_DIR"

        if $PRE_COMMIT; then
            # Staging the generated diagrams
            git add "$OUTPUT_DIR"
        fi

        # Remove temporary folder
        rm -rf "$TEMP_DIR"
        echo Done!
    else
        # Remove temporary folder
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi
