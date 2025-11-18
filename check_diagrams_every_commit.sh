#!/bin/sh

set -eu

usage() {
    BASENAME=$(basename "$0")
    cat <<EOF
Usage:
    1) $BASENAME [-h] [-f] <base-commit> <head> <command>

Description:
    Runs <command> for each commit from <base-commit> (excluded) up to <head>.
    After running <command> checks if there are any changes in the repository.
    If any change is found in any of the selected commits the script will exit with
    an error exit code.
    The idea is that for each commit you generate the diagrams through <command> and
    then check if anything changes, if not it means that the diagrams were already
    correctly generated.

Options:
    -h
        Show this message and exit

    -f  
        (fail-fast) The script will immediately exit upon detecting the first commit
        for which changes are detected.

Examples:
    $BASENAME e575715bc1775f6e5729f9925d196de2719868b9 HEAD ./gen_puml_diagrams.sh
    $BASENAME -f e575715bc1775f6e5729f9925d196de2719868b9 29cc65688a8c056c7a6c25c87e063aabc4cd2e3c ./gen_puml_diagrams.sh
EOF
}

FAIL_FAST=false

while getopts ':hf' opt; do
    case $opt in
    h)
        usage
        exit
        ;;
    f)
        FAIL_FAST=true
        ;;
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

if [ $# -ne 3 ]; then
    usage
    exit 1
fi

BASE_COMMIT="$1"
HEAD="$2"
COMMAND="$3"
COMMIT_TO_RESTORE=$(git log -1 --format="%H")

COMMITS=$(git log --format="%H" --reverse "$BASE_COMMIT..$HEAD")
echo "Commits to check:"
echo "$COMMITS"

FAILED_COMMITS=""

reset() {
    git reset --hard && git clean -fd # Remove all changes (including untracked files)
}

cleanup() {
    reset
    git checkout "$COMMIT_TO_RESTORE"
}

trap cleanup EXIT

for C in $COMMITS; do
    git checkout --quiet "$C"

    if ! $COMMAND; then
        echo "Error: Command '$COMMAND' failed for commit $C." >&2
        exit 1
    fi

    if [ -n "$(git status --porcelain)" ]; then
        FAILED_COMMITS="$FAILED_COMMITS\n$C"
        echo "DIAGRAMS NOT UP TO DATE IN COMMIT: $C"
        if $FAIL_FAST; then
            echo "Fail-fast enabled: exiting immediately with failure."
            break
        fi
        reset
    fi
done

if [ -n "$FAILED_COMMITS" ]; then
    exit 1
else
    echo "All commits passed the check."
fi
