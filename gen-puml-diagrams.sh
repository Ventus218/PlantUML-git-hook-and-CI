#!/bin/sh

# This scripts generates the PUML diagrams for every commit.
# It aims at generating diagrams according to the actually staged changes.

# Redirect output to stderr.
exec 1>&2

set -eu

show_help() {
	echo "Usage: $0 [-o] <puml sources folder> <output folder>"
	echo "       -o to generate diagrams only for staged changes"
	echo "       -s to automatically stage all generated diagrams"
}

ONLY_STAGED=false
STAGE_GENERATED_DIAGRAMS=false

while getopts 'hos' opt; do
	case $opt in
	h)
		show_help
		exit
		;;
	o) ONLY_STAGED=true ;;
	s) STAGE_GENERATED_DIAGRAMS=true ;;
	esac
done
shift "$((OPTIND - 1))"

if [ $# -lt 2 ]; then
	show_help
	exit 1
fi

IN_DIR="$1"
OUT_DIR="$2"

if ! which docker >&/dev/null; then
	echo "Docker is required for generating PlantUML diagrams"
	exit 1
fi

# Checks if there are any changes in the sources or in the generated diagrams
# If ONLY_STAGED is set we check only for staged changes
if ! git diff --quiet $($ONLY_STAGED && echo --staged) -- "$IN_DIR" "$OUT_DIR"; then

	# Pulling the image before doing anything in so that we do nothing if the pull fails
	echo "Pulling plantuml image"
	docker pull plantuml/plantuml:latest >&/dev/null

	if $ONLY_STAGED; then
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

	if $ONLY_STAGED; then
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

		if $STAGE_GENERATED_DIAGRAMS; then
			# Staging the generated diagrams in order to commit them
			git add "$OUT_DIR"
		fi

		# Remove temporary folder
		rm -rf "$TEMP_DIR"
	else
		# Remove temporary folder
		rm -rf "$TEMP_DIR"
		exit 1
	fi
fi
