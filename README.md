# PlantUML git hook and CI

This repo aims at providing a way of managing PlantUML diagrams so that when
embedded in Markdown documents:

- they are rendered on GitHub
- they are visible locally even when offline
- they are up to date for every single commit

To achieve that you should be using a combination of two techniques:

- a pre-commit git hook which generates the diagrams before committing
- a CI pipeline that checks for every pushed commit that the diagrams were
  generated (WIP)

The idea is that most of the times updated diagrams will just be pushed
alongside the source changes thanks to the git hook. However it is not possible
to ensure that the hook is installed by every user and this is why we provide CI
pipelines that checks that for each pushed commit the diagrams were correctly
generated.

## Install

### Download the script

Docker is required as it is used to run the plantuml container which generates
the diagrams.

```sh
wget https://raw.githubusercontent.com/Ventus218/PlantUML-git-hook-and-CI/refs/heads/main/gen_puml_diagrams.sh
chmod u+x gen_puml_diagrams.sh
```

This script is tought to be committed to your repo so that everybody who will
clone the repo won't need to install it.

### Configuration

To keep it DRY the suggested way to tell the script where to find the sources
and where to place generated diagrams is through a configuration file.

```sh
# gen_puml_diagrams_config.sh
INPUT_DIR=diagrams/src
OUTPUT_DIR=diagrams/gen
```

The script will automatically search for the configuration file by recursively
going upward in the file tree

> **Note:**
>
> If you want more flexibility take a look at the script help to see other ways
> in which it can be configured
>
> ```sh
> ./gen_puml_diagrams.sh -h
> ```

### Setup the pre-commit git hook

If you want to automatically generate the PlantUML diagrams as a pre-commit git
hook paste this in you pre-commit file:

```sh
# .git/hooks/pre-commit
REPO_ROOT="$(dirname $0)/../.."
$REPO_ROOT/gen_puml_diagrams.sh -p
```

### Setup CI

_Work in progress_

## Usage

If you want to generate the diagrams manually you can run:

```sh
./gen_puml_diagrams.sh
```
