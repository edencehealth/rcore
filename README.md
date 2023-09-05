# rcore

This repository houses the source code for the [edenceHealth](https://edence.health/) Docker image [`edence/rcore`](https://hub.docker.com/r/edence/rcore). This image is used as the base for many of our containers which require the [R programming language](https://www.r-project.org/).

Built on the current Debian "stable" release, this image includes essential R packages (`r-base-dev`, `r-recommended`, and `r-cran-remotes`) from the distribution, alongside the [Temurin JDK](https://adoptium.net/temurin/releases/).

## "nonroot" reduced privilege user account

For improved runtime security, this image includes a `nonroot` user account, which aligns with the UID and GID used by the [Google "distoless"](https://github.com/GoogleContainerTools/distroless) images. This user account can be implemented in child images by using the `USER nonroot` Dockerfile directive or via the `--user` / `-u` `docker run` arguments.

## Utility Programs

The image includes the following utility programs intended for use by downstream consumers:

### "txt2lock" lockfile generation helper

txt2lock.R is a utility that generates `renv.lock` files from `renv.txt` files. An `renv.txt` file is a list of package specifications, one per line, as provided to `renv::install`. This allows a loose list of package requirements to generate a much more specific `renv.lock` file, which contains exact package version numbers/specifications for all dependencies. The program generates the `renv.lock` file by calling `renv::snapshot` with `snapshot.type="all"`.


### "patch4ref" patch script runner

patch4ref is a utility for executing patch scripts, using a GIT_REF environment variable as a reference. The script is included from: <https://github.com/edencehealth/patch4ref/>.
