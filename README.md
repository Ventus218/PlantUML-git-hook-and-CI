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

# Version tag of the docker image plantuml/plantuml to use, it is passed
# directly to docker so any valid tag is okay.
# ("latest" should not be used when also exploiting the CI check pipeline as
# the pipeline must know exactly what version was used for the specific commit under
# examination
PUML_VERSION_TAG="1.2025.10"
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

> **Note:**
>
> When using the CI pipeline you it is important to check the creation of
> diagrams by using the same PlantUML version that was used for the specific
> commit. This is why using "latest" as PUML_VERSION_TAG is a bad idea.

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

## 🤔 Why these decisions were made

The approach outlined for managing PlantUML diagrams involves some
decisions—specifically, **committing generated diagrams** and **using a
pre-commit hook over relying solely on CI**—that deviate from typical software
development best practices. Here is the rationale behind these choices,
prioritizing **consistency, visibility, and reliability** in documentation.

### Why commit generated diagrams?

Generally, committing build artifacts or generated files is discouraged to keep
repositories lean and history clean. However, for PlantUML diagrams embedded in
**Markdown documentation**, this practice becomes really useful for two reasons:

1.  **Platform rendering (e.g., GitHub):** Platforms like GitHub, GitLab, and
    Bitbucket **do not** automatically render raw PlantUML code blocks into
    images (unlike some support for **Mermaid**). To have a visible diagram
    _instantly_ rendered within your documentation, you must provide a standard
    image file (like an SVG or PNG) and link to it.
2.  **Offline and reliable viewing:** While some tools offer a workaround by
    generating shortened URLs to the PlantUML online server, this presents two
    major problems:
    - It requires an **active internet connection** to view the documentation,
      even if you have the repository fully cloned on your machine.
    - It introduces a **dependency** on an external service (the link shortener
      and the PlantUML server) to remain online and functional forever.

By **committing the generated image files**, we ensure the diagrams are:

- ✅ **Rendered instantly** on all repository hosting services.
- ✅ **Viewable locally and offline** by all users immediately after cloning.
- ✅ **Independent** of external online services for display.

### Why a git hook and not just CI generation?

Relying _only_ on a CI pipeline to generate and push updated diagrams back to
the repository leads to several undesirable outcomes that compromise commit
integrity and workflow:

- **Polluted commit history**: The CI system would be forced to create and push
  commits (e.g., "[CI] Update PlantUML diagrams") after every source change.
  This **clutters the history** with automated, non-contextual commits, making
  the timeline harder to read and audit.
- **Diagram synchronization gaps**: Without a pre-commit hook, the diagrams
  would be **out of date** for the _initial_ commit that changes the source code
  (`.puml` file). The diagrams would only become current _after_ the CI job runs
  and pushes its follow-up commit.
- **Complex history rewrites**: To avoid the second commit, CI would have to
  perform **risky history rewrites** on the branch, which is often difficult,
  disallowed, and can lead to significant synchronization issues for other
  developers.

The **pre-commit git hook** solves these issues by guaranteeing that the
generated diagram file is **created and staged** _before_ the commit is
finalized. This ensures that every single commit contains **synchronously
up-to-date** diagram images, keeping the history clean and documentation
consistent from the moment of creation.
