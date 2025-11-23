#!/bin/sh

set -eu

FAILED=""
PASSED=""

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

PUML_VERSION_TAG=1.2025.10
TEST_DIR=test_dir

cleanup() {
    cd "$SCRIPT_DIR"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Takes one parameter, executes it as a command and tracks if it
# succeds or fails, generating a report.
# You should define your test in a function and then pass it to run_test.
# run_test will automatically cd in a clean git dir on every invocation.
run_test() {
    TEST="$1"

    mkdir "$TEST_DIR"
    cd "$TEST_DIR"

    git init --quiet
    # This is needed when running this test in CI
    git config --local user.name "Tests"
    git config --local user.email "tests@tests"

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

action_fails_if_any_commit_is_bad() {
    # making initial commit
    git commit --quiet --allow-empty --allow-empty-message -m ""
    BASE_COMMIT=$(git log -1 --format="%H")
    mkdir src
    mkdir gen
    touch gen/.gitignore # just to commit gen otherwise it would be deleted
    cat >src/d.puml <<EOF
@startuml
Bob -> Alice : hello
@enduml
EOF
    git add .
    git commit --quiet --allow-empty-message -m ""

    ! ../../action.sh "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen $PUML_VERSION_TAG"
}
run_test action_fails_if_any_commit_is_bad

action_succeeds_if_no_commit_is_bad() {
    # making initial commit
    git commit --quiet --allow-empty --allow-empty-message -m ""
    BASE_COMMIT=$(git log -1 --format="%H")
    mkdir src
    mkdir gen
    touch gen/.gitignore # just to commit gen otherwise it would be deleted
    cat >src/d.puml <<EOF
@startuml
Bob -> Alice : hello
@enduml
EOF
    ../../gen_puml_diagrams.sh src gen $PUML_VERSION_TAG
    git add .
    git commit --quiet --allow-empty-message -m ""

    ../../action.sh "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen $PUML_VERSION_TAG"
}
run_test action_succeeds_if_no_commit_is_bad

action_prints_bad_commits_to_stdout() {
    # making initial commit
    git commit --quiet --allow-empty --allow-empty-message -m ""
    BASE_COMMIT=$(git log -1 --format="%H")
    mkdir src
    mkdir gen
    touch gen/.gitignore # just to commit gen otherwise it would be deleted
    cat >src/d.puml <<EOF
@startuml
Bob -> Alice : hello
@enduml
EOF
    git add .
    git commit --quiet --allow-empty-message -m ""
    EXPECTED_BAD_COMMIT=$(git log -1 --format="%H")
    git commit --quiet --allow-empty --allow-empty-message -m ""
    EXPECTED_BAD_COMMIT="$EXPECTED_BAD_COMMIT
$(git log -1 --format="%H")"
    OUTPUT="$(../../action.sh "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen $PUML_VERSION_TAG")"

    [ "$OUTPUT" = "$EXPECTED_BAD_COMMIT" ]
}
run_test action_prints_bad_commits_to_stdout

action_stops_at_first_failing_commit_with_failfast_enabled() {
    # making initial commit
    git commit --quiet --allow-empty --allow-empty-message -m ""
    BASE_COMMIT=$(git log -1 --format="%H")
    mkdir src
    mkdir gen
    touch gen/.gitignore # just to commit gen otherwise it would be deleted
    cat >src/d.puml <<EOF
@startuml
Bob -> Alice : hello
@enduml
EOF
    git add .
    git commit --quiet --allow-empty-message -m ""
    EXPECTED_BAD_COMMIT=$(git log -1 --format="%H")
    git commit --quiet --allow-empty --allow-empty-message -m ""
    OUTPUT="$(../../action.sh -f "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen $PUML_VERSION_TAG")"

    [ "$OUTPUT" = "$EXPECTED_BAD_COMMIT" ]
}
run_test action_stops_at_first_failing_commit_with_failfast_enabled

action_uses_specified_puml_version() {
    # making initial commit
    git commit --quiet --allow-empty --allow-empty-message -m ""
    BASE_COMMIT=$(git log -1 --format="%H")
    mkdir src
    mkdir gen
    touch gen/.gitignore # just to commit gen otherwise it would be deleted
    cat >src/d.puml <<EOF
@startuml
' The following diagram uses a feature that is new in PlantUML 1.2025.10
skinparam linetype ortho
!pragma edgeCornerRadius 15
[*] --> A
A --> B
A --> C
@enduml
EOF
    OLD_PUML_VERSION_TAG=1.2022
    ../../gen_puml_diagrams.sh src gen "$OLD_PUML_VERSION_TAG" # Notice we use an older version here
    git add .
    git commit --quiet --allow-empty-message -m ""

    # The rationale behind this test is that using the wrong version may generally (though not surely) cause
    # generation mismatch and therefore a failure in checking
    (! ../../action.sh -f "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen $PUML_VERSION_TAG") &&
        (../../action.sh -f "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen $OLD_PUML_VERSION_TAG")
}
run_test action_uses_specified_puml_version

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
