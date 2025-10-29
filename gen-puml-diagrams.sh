#!/bin/sh

# Redirect output to stderr.
exec 1>&2

set -eu

usage() {
	cat <<EOF
Usage: $(basename "$0") [options] <diagram sources folder> <output folder>

Generate PlantUML diagrams contained in <diagram sources folder> into
<output folder> maintaining the folders structure.

Options:
  -h  Show this help and exit
  -p  (pre-commit) The script will generate diagrams reflecting only the staged
      changes and adding the generated diagrams to the stage. It is meant to be
      run as a pre-commit git hook

Examples:
  $(basename "$0") diagrams/src diagrams/gen
  $(basename "$0") -p diagrams/src diagrams/gen
EOF
}

PRE_COMMIT=false

while getopts ':hp' opt; do
	case $opt in
	h)
		usage
		exit
		;;
	p) PRE_COMMIT=true ;;
	:)
		echo "Error: Option -$OPTARG requires an argument."
		usage
		exit 1
		;;
	\?)
		echo "Error: Invalid option -$OPTARG"
		usage
		exit 1
		;;
	esac
done
shift "$((OPTIND - 1))"

if [ $# -lt 2 ]; then
	usage
	exit 1
fi

IN_DIR="$1"
OUT_DIR="$2"

if ! which docker >&/dev/null; then
	echo "Docker is required for generating PlantUML diagrams"
	exit 1
fi

# If PRE_COMMIT is set we check if there are staged changes
if ! $PRE_COMMIT || ! git diff --quiet --staged -- "$IN_DIR" "$OUT_DIR"; then

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
	cp -r "$IN_DIR/"* "$TEMP_SRC"

	if $PRE_COMMIT; then
		# Resetting the repo in order to avoid merge conflicts when popping the stash
		git reset --quiet --hard
		# Here we pop while also restoring the index because from now on we can work on the temp folder
		git stash pop --quiet --index
	fi

	echo "Generating UML diagrams"
	if docker run --rm -v /${TEMP_DIR}:/data plantuml/plantuml:latest -failfast2 -o ../gen //data/src; then
		# Substituting the generated folder with the new one
		rm -rf "$OUT_DIR"
		cp -r "$TEMP_GEN" "$OUT_DIR"

		if $PRE_COMMIT; then
			# Staging the generated diagrams
			git add "$OUT_DIR"
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
