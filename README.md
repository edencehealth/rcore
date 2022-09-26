# r-core

A base image for eH containers that use R and Java.

## nonroot user

This container creates a `nonroot` user with the same uid/gid used by the
"distoless" containers.

## txt2lock.R

This image contains the utility `txt2lock.R`. This is a utility for generating
renv.lock files. It is on the execution path under `/bin`.

### txt2lock usage

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