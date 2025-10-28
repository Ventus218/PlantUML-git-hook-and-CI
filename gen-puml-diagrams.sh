#!/bin/sh

# This scripts generates the PUML diagrams for every commit.
# It aims at generating diagrams according to the actually staged changes.

# Redirect output to stderr.
exec 1>&2

if ! which docker >&/dev/null; then
	echo "Docker is required for generating PlantUML diagrams"
	exit 1
fi

PROJECT_ROOT="$(pwd)/$(dirname $0)/../.."
DIAGRAMS_DIR="${PROJECT_ROOT}/doc/diagrams"

# Checks if there are any staged changes in the diagrams
if ! git diff --quiet --staged -- "$DIAGRAMS_DIR"; then

	# Stashing everything that is not staged (so we can build images only of what will be committed)
	git stash push --quiet --keep-index --include-untracked

	# Copying the diagrams folder into a temporary one
	TEMP_DIR=$(mktemp -d)
	cp -r "$DIAGRAMS_DIR/"* "$TEMP_DIR"

	# Resetting the repo in order to avoid merge conflicts when popping the stash
	git reset --quiet --hard
	# Removing untracked files as this is not done by git reset (they will be restored when popping the stash)
	git clean --quiet -fd

	git stash pop --quiet --index

	# From now on we can safely work on the temp folder

	# Removing all the diagrams so that if a src was deleted the generated diagram will be deleted as well
	rm -f "$TEMP_DIR/generated/"*

	echo "Pulling plantuml image"
	docker pull plantuml/plantuml:latest >&/dev/null

	echo "Generating UML diagrams"
	if docker run --rm -v /${TEMP_DIR}:/data plantuml/plantuml:latest -failfast2 -o ../generated //data/src; then
		# Substituting the generated folder with the new one
		rm -rf "$DIAGRAMS_DIR/generated"
		cp -r "$TEMP_DIR/generated" "$DIAGRAMS_DIR/generated"

		# Staging the generated diagrams in order to commit them
		git add "$DIAGRAMS_DIR/generated"

		# Remove temporary folder
		rm -rf "$TEMP_DIR"
	else
		# Remove temporary folder
		rm -rf "$TEMP_DIR"
		exit 1
	fi
fi
