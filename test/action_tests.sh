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

# ~~~~~~~~~~ TEST 1 ~~~~~~~~~~

mkdir "$TEST_DIR"
cd "$TEST_DIR"
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

if ../../action.sh -f "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen"; then
    echo "Test 1 not passed"
    FAILED="${FAILED}Test1 "
else
    echo "Test 1 passed"
    PASSED="${PASSED}Test1 "
fi
cd ..
rm -rf "$TEST_DIR"

# ~~~~~~~~~~ TEST 2 ~~~~~~~~~~

mkdir "$TEST_DIR"
cd "$TEST_DIR"
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

if ../../action.sh -f "$BASE_COMMIT" HEAD "../../gen_puml_diagrams.sh src gen"; then
    echo "Test 2 passed"
    PASSED="${PASSED}Test2 "
else
    echo "Test 2 not passed"
    FAILED="${FAILED}Test2 "
fi
cd ..
rm -rf "$TEST_DIR"

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
