# PlantUML Git Hook and CI

This repository provides all the tools to ensure your PlantUML diagrams are
**consistently rendered, visible, and current** across your documentation.

The implementation ensures that PlantUML diagrams embedded within your Markdown
documents meet three critical criteria:

- ✅ They are **rendered instantly** on platforms such as **GitHub**.
- ✅ They are **visible locally** without requiring an active internet
  connection.
- ✅ They are guaranteed to be **synchronously up-to-date** with every committed
  change.

## Dependencies

**Docker** is required to be installed, as the generation script uses it to run
the PlantUML container.

## Install

### Step 1: Obtain the generation script

Download the generation script and set its execution permissions. This script is
intended to be **committed to your repository** to ensure it is readily
available to all contributors upon cloning.

```sh
wget https://raw.githubusercontent.com/Ventus218/PlantUML-git-hook-and-CI/main/gen_puml_diagrams.sh
chmod u+x gen_puml_diagrams.sh
```

> **Note:**
>
> You can actually name the script whatever you want, just make sure to adjust
> the next steps with the name you choose

### Step 2: Configuration

The script relies on a configuration file to define the locations of the
PlantUML source files (`.puml`) and the output directory for the generated
images.

Create a file named `gen_puml_diagrams_config.sh` in the root directory of your
repository.

```sh
# gen_puml_diagrams_config.sh
# Directory containing source .puml files
INPUT_DIR=diagrams/src

# Directory where generated images (e.g., .svg, .png) will be placed
OUTPUT_DIR=diagrams/gen
```

> **Note:**
>
> The generation script will search for a configuration file named
> `gen_puml_diagrams_config.sh` by going upward in the file tree from its
> position.
>
> You can actually name the configuration file whatever you want or store it
> wherever you like but then you will need to manually specify its location to
> the generation script:
>
> ```sh
> ./gen_puml_diagrams.sh -c <config-file>
> ```

### Step 3: Configure the pre-commit git hook

This step establishes the automatic generation process. Integrating the script
as a `pre-commit` hook ensures that diagrams are generated **prior to** every
commit, maintaining synchronization between your documentation and codebase
changes.

Insert the following commands into your **`.git/hooks/pre-commit`** file:

```sh
# .git/hooks/pre-commit

# Determine the repository root path
REPO_ROOT="$(dirname $0)/../.."

# Execute the generator script in pre-commit mode (-p)
$REPO_ROOT/gen_puml_diagrams.sh -p
```

### Step 4: Setup CI

While the git hook automates the process, strict enforcement that every
contributor has correctly installed the hook is not guaranteed.

Our CI pipeline will check that each new commit has up-to-date diagrams.

TODO: setup CI example

## Manual execution and configuration details

### Manual diagram generation

Should you need to manually generate all diagrams—for instance, to verify output
or after the initial configuration—the script can be executed without any
options:

```sh
./gen_puml_diagrams.sh
```

### Advanced script configuration

The script supports additional configuration flexibility (e.g., specifying
configuration or input/output directories via command-line flags). Consult the
help documentation for a comprehensive overview:

```sh
./gen_puml_diagrams.sh -h
```
