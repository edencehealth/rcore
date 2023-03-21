#!/usr/bin/Rscript
library("docopt")

'txt2lock

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

' -> doc

args <- docopt(doc)

renv::init()
for (pkg in readLines(args$txtfile)) {
  renv::install(pkg)
}
renv::settings$snapshot.type("all")
renv::snapshot()
cat(readLines("renv.lock"), sep = "\n")
