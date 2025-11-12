# PlantUML git hook and CI

This repo aims at providing a way of managing PlantUML diagrams so that when
embedded in Markdown documents:

- they are rendered on GitHub
- they are visible locally even when offline
- they are up to date for every single commit

To achieve that you should be using a combination of two techniques:

- a pre-commit git hook which generates the diagram before committing
- a GitHub action that checks for every commit that the diagrams were generated
  (WIP)

## Install

Docker is required as it is used to run the plantuml container which generates
the diagrams.

```sh
wget https://raw.githubusercontent.com/Ventus218/PlantUML-git-hook-and-CI/refs/heads/main/gen-puml-diagrams.sh
```

## Usage

If you want to automatically generate the PlantUML diagrams as a pre-commit git
hook paste this in you pre-commit file:

```sh
REPO_ROOT="$(dirname $0)/../.."
$REPO_ROOT/gen-puml-diagrams.sh -p <diagram sources folder> <output folder>
```

Otherwise if you just want to generate the diagrams you can run:

```sh
./gen-puml-diagrams.sh <diagram sources folder> <output folder>
```
