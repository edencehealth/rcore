# rcore

This repository contains the source code for building the Docker image which serves as the base image for several of the [edenceHealth](https://edence.health/) Docker images that depend on [the R software environment](https://www.r-project.org/).

This image is based on the current debian "testing" release and it adds that distribution's default essential R packages, (such as `r-base-dev`, `r-recommended`, and `r-cran-remotes`) and OpenJDK 11.

## "nonroot" reduced privilege user account

This image has a `nonroot` user with the same UID and GID used by the [Google "distoless"](https://github.com/GoogleContainerTools/distroless) images. This user account can be used in child images to improve runtime security (via the `USER nonroot` Dockerfile directive or via a `docker run` argument)

## Utility Programs

The image includes some utilities that are used by downstream consumers.

### "txt2lock" lockfile generation helper

This image contains the command-line utility `txt2lock.R`. This is a utility for generating `renv.lock` files from `renv.txt` files. By default it is installed in the execution path under `/bin`.

#### txt2lock usage

```
txt2lock

A utility for generating renv.lock files from renv.txt files.

An "renv.txt" file is a list (one-per-line) of package specifications, as given
to "renv::install". This enables a loose list of package requirements to
generate a much more specific "renv.lock" file which contains exact package
version numbers / specifications for all dependencies. The program generates
the "renv.lock" by calling renv::snapshot with snapshot.type="all".

Usage:
  txt2lock.R [options] <txtfile>

General options:
  -h, --help              Show this help message.

```

### "patch4ref" patch script runner

This utility is for running patch scripts based on a `GIT_REF` environment variable. The script is included from: <https://github.com/edencehealth/patch4ref/>
