#!/usr/bin/env bash

# ===> HEADER SECTION START  ===>

# http://bash.cumulonim.biz/NullGlob.html
shopt -s nullglob
# -------------------------------
this_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -z "$this_folder" ]; then
  this_folder=$(dirname "$(readlink -f "$0")")
fi
# -------------------------------
# --- required functions
debug(){
    local __msg="$1"
    echo " [DEBUG] $(date) ... $__msg "
}

info(){
    local __msg="$1"
    echo " [INFO]  $(date) ->>> $__msg "
}

warn(){
    local __msg="$1"
    echo " [WARN]  $(date) *** $__msg "
}

err(){
    local __msg="$1"
    echo " [ERR]   $(date) !!! $__msg "
}

file_age_days() {
  local file="$1"
  local file_time
  local current_time

  if [[ "$OSTYPE" == "darwin"* ]]; then
      file_time=$(stat -f %m "$file")
  else
      file_time=$(stat -c %Y "$file")
  fi

  current_time=$(date +%s)
  echo $(( (current_time - file_time) / 86400 ))
}

# ---------- CONSTANTS ----------
export FILE_VARIABLES=${FILE_VARIABLES:-".variables"}
export FILE_LOCAL_VARIABLES=${FILE_LOCAL_VARIABLES:-".local_variables"}
export FILE_SECRETS=${FILE_SECRETS:-".secrets"}
export INCLUDE_FILE=".bashutils"

# -------------------------------
# --- source variables files
if [ ! -f "$this_folder/$FILE_VARIABLES" ]; then
  warn "we DON'T have a $FILE_VARIABLES variables file - creating it"
  touch "$this_folder/$FILE_VARIABLES"
else
  # shellcheck disable=SC1090
  . "$this_folder/$FILE_VARIABLES"
fi

if [ ! -f "$this_folder/$FILE_LOCAL_VARIABLES" ]; then
  warn "we DON'T have a $FILE_LOCAL_VARIABLES variables file - creating it"
  touch "$this_folder/$FILE_LOCAL_VARIABLES"
else
  # shellcheck disable=SC1090
  . "$this_folder/$FILE_LOCAL_VARIABLES"
fi

if [ ! -f "$this_folder/$FILE_SECRETS" ]; then
  warn "we DON'T have a $FILE_SECRETS secrets file - creating it"
  touch "$this_folder/$FILE_SECRETS"
else
  # shellcheck disable=SC1090
  . "$this_folder/$FILE_SECRETS"
fi

# ---------- include bashutils ----------
# --- refresh file if older than 1 day
bashutils="$this_folder/$INCLUDE_FILE"
[ "$(file_age_days "$bashutils")" -gt 1 ] && \
  curl -sf https://raw.githubusercontent.com/jtviegas/bashutils/master/.bashutils -o "${bashutils}.tmp" && \
  mv "${bashutils}.tmp" "$bashutils"
# --- source it
# shellcheck disable=SC1090
. "$bashutils"

# <=== HEADER SECTION END  <===

# ===> MAIN SECTION START  ===>

# ---------- CONSTANTS ----------
export MYSYS_FOLDER="$this_folder/.mysys"
export TAR_FILE="mysys.tar.bz2"

# ---------- FUNCTIONS ----------

shlint(){
  info "[shlint|in]"

  _pwd=$(pwd)
  # shellcheck disable=SC2164
  cd "$this_folder"

  shellcheck helper.sh && shellcheck .mysys/bin/mysys.sh
  result="$?"
  # shellcheck disable=SC2164
  cd "$_pwd"
  [ ! "$result" -eq "0" ] && err "[shlint|out] lint failed" && exit 1

  info "[shlint|out]"
}

release(){
  info "[release] ..."

  echo "$VERSION" > "$MYSYS_FOLDER/bin/.version"
  tar cjpvf "$TAR_FILE" -C "$MYSYS_FOLDER" .
  result="$?"
  [ ! "$result" -eq "0" ] && err "[release] could not tar it" && exit 1

  info "[release] ...done."
}

# <=== MAIN SECTION END  <===

# ===> FOOTER SECTION START  ===>

usage() {
  cat <<EOM
  usage:
  $(basename "$0") { option }
    options:
      - release:                  packages mysys into a tar for release purposes
      - shlint:                   lints the shell scripts
      - get_latest_tag            retrieves the latest git tag from the repository
      - tag COMMIT_HASH           creates a git tag and pushes it to remote repository, version is defined in .variables file
EOM
  exit 1
}

# -------------------------------------

case "$1" in
  get_latest_tag)
    get_latest_tag
    ;;
  tag)
    git_tag_and_push "$VERSION" "$2"
    ;;
  release)
    release
    ;;
  shlint)
    shlint
    ;;
  *)
    usage
    ;;
esac


# <=== FOOTER SECTION END  <===