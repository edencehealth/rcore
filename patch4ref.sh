#!/bin/sh
# patch4ref: apply patches based on the GIT_REF environment variable
# shellcheck disable=SC2317
SELF=$(basename "$0" '.sh')
set -eu

log() {
  printf '%s %s %s\n' "$(date '+%FT%T%z')" "$SELF" "$*" >&2
}

die() {
  log "FATAL:" "$@"
  exit 1
}

parse_bool() {
  # return true if the arguments are truthy
  printf '%s' "$*" | \
    grep -qiE '^[[:space:]]*(1|enable|on|t(rue)?|y(es)?)[[:space:]]*$'
}

usage() {
  exception="${1:-}";
  if [ -n "$exception" ]; then
    print '%s\n\n' "$exception" >&2
  fi

  printf '%s\n' \
    "Usage: $0 [-h|--help] [--strict] [--patch-dir PATCH_DIR] [--git-ref GIT_REF]" \
    "" \
    "The program evaluates the GIT_REF environment variable" \
    "(or the \"--git-ref GIT_REF\" cli argument). For the given GIT_REF," \
    "this program applies patches to the source code to make the container" \
    "work (or work better). The GIT_REF can be in any of these formats:" \
    "" \
    "* refs/tags/v2.12.1" \
    "* 2.12.1" \
    "* v2.12.1" \
    "* v2.12" \
    "* v2" \
    "" \
    "If given the --strict flag, the program will exit non-zero if no patch" \
    "was found for the given git ref." \
    ""

  [ -n "$exception" ] && exit 1
  exit 0
}

main() {
  GIT_REF="${GIT_REF:-}"
  PATCH_DIR="${PATCH_DIR:-patches}"
  STRICT="${STRICT:-0}"

  while [ $# -gt 0 ]; do
    arg="$1" # shift at end of loop; if you break inside the loop, shift first
    case "$arg" in
      -h|--help)
        usage
        ;;

      --git-ref)
        shift || die "--git-ref requires an argument"
        GIT_REF="$1"
        ;;

      --patch-dir)
        shift || die "--patch-dir requires an argument"
        PATCH_DIR="$1"
        ;;

      --strict)
        STRICT=1
        ;;

      *)
        usage "Unknown argument ${arg}"
        ;;
    esac
    shift || break
  done

  printf '  %s="%s"\n' \
    "GIT_REF" "$GIT_REF" \
    "PATCH_DIR" "$PATCH_DIR" \
    "STRICT" "$STRICT" \
  >&2;

  [ -n "${GIT_REF}" ] || die "GIT_REF is required to be set in the" \
    "environment (or specified as a CLI-argument)"

  [ -d "$PATCH_DIR" ] || die "PATCH_DIR \"${PATCH_DIR}\" is not a valid" \
    "directory"

  semver3="${GIT_REF##*/}"   # major.minor.patch
  semver2="${semver3%.*}"    # major.minor
  semver1="${semver3%.*.*}"  # major

  for v in "$semver3" "$semver2" "$semver1"; do
    patch="${PATCH_DIR}/${v}.sh"
    log "DEBUG: checking for ${patch}"
    if [ -f "$patch" ]; then
      log "applying patch ${patch} for ref ${GIT_REF}"
      /bin/sh -c "${patch}" || die "Failed running patch file"
      log "done"
      exit 0
    fi
  done

  status="no patch was found for ref \"${GIT_REF}\""
  if parse_bool "$STRICT"; then
    die "strict mode: ${status}"
  fi
  log "WARNING: ${status}"
  exit 0
}

main "$@"; exit
