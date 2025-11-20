#!/bin/sh

set -eu

FAILED=""
PASSED=""

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

TEST_DIR=test_dir

cleanup() {
    cd "$SCRIPT_DIR"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Takes one parameter, executes it as a command and tracks if it
# succeds or fails, generating a report.
# You should define your test in a function and then pass it to run_test.
# run_test will automatically cd in a clean dir on every invocation.
run_test() {
    TEST="$1"

    mkdir "$TEST_DIR"
    cd "$TEST_DIR"

    echo "Running $TEST ..."
    if $TEST >/dev/null 2>&1; then
        printf "\033[1A\033[2K"
        echo "✅ $TEST"
        PASSED="$PASSED
        $TEST"
    else
        printf "\033[1A\033[2K"
        echo "❌ $TEST"
        FAILED="$FAILED
        $TEST"
    fi
    cleanup
}

action_fails_if_diagrams_not_generated_correctly_on_first_commit() {
    git init
    # making initial commit
    git commit --allow-empty --allow-empty-message -m ""
    BASE_COMMIT=$(git log -1 --format="%H")
    mkdir src
    mkdir gen
    cat >src/d.puml <<EOF
@startuml
Bob -> Alice : hello
@enduml
EOF
    git add .
    git commit --allow-empty-message -m ""

    ! ../../action.sh -f "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen"
}
run_test action_fails_if_diagrams_not_generated_correctly_on_first_commit

action_succeed_if_diagrams_are_generated_correctly_on_first_commit() {
    git init
    # making initial commit
    git commit --allow-empty --allow-empty-message -m ""
    BASE_COMMIT=$(git log -1 --format="%H")
    mkdir src
    mkdir gen
    cat >src/d.puml <<EOF
@startuml
Bob -> Alice : hello
@enduml
EOF
    ../../gen_puml_diagrams.sh src gen
    git add .
    git commit --allow-empty-message -m ""

    ../../action.sh -f "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen"
}
run_test action_succeed_if_diagrams_are_generated_correctly_on_first_commit

echo PASSED:
for T in $PASSED; do
    echo "  $T"
done
echo
echo FAILED:
for T in $FAILED; do
    echo "  $T"
done

if [ -n "$FAILED" ]; then
    exit 1
fi
