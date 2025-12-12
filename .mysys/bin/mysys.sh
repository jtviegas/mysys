#!/usr/bin/env bash

# ===> COMMON SECTION START  ===>

# http://bash.cumulonim.biz/NullGlob.html
shopt -s nullglob
# -------------------------------
this_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -z "$this_folder" ]; then
  this_folder=$(dirname $(readlink -f $0))
fi
mysys_folder=$(dirname "$this_folder")
env_folder="$mysys_folder/env"
# -------------------------------
debug(){
    local __msg="$1"
    echo " [DEBUG] `date` ... $__msg "
}

info(){
    local __msg="$1"
    echo " [INFO]  `date` ->>> $__msg "
}

warn(){
    local __msg="$1"
    echo " [WARN]  `date` *** $__msg "
}

err(){
    local __msg="$1"
    echo " [ERR]   `date` !!! $__msg "
}

# ---------- CONSTANTS ----------
export FILE_VARIABLES=${FILE_VARIABLES:-".variables"}
export FILE_SECRETS=${FILE_SECRETS:-".secrets"}
export TAR_FILE="mysys.tar.bz2"
export CLAUDE_FOLDER="~/.claude"
# -------------------------------
if [ ! -f "$env_folder/$FILE_VARIABLES" ]; then
  warn "we DON'T have a $FILE_VARIABLES variables file - creating it"
  touch "$env_folder/$FILE_VARIABLES"
else
  . "$env_folder/$FILE_VARIABLES"
fi

if [ ! -f "$env_folder/$FILE_SECRETS" ]; then
  warn "we DON'T have a $FILE_SECRETS secrets file - creating it"
  touch "$env_folder/$FILE_SECRETS"
else
  . "$env_folder/$FILE_SECRETS"
fi

# ---------- FUNCTIONS ----------

update(){
  echo "[update] ..."

  _pwd=`pwd`

  if [ ! -d "$mysys_folder" ]; then
    err "can't find $mysys_folder folder ! sorry I am leaving"
    exit 1
  fi

  cd "$mysys_folder"

  curl -L https://api.github.com/repos/jtviegas/mysys/releases/latest | grep "browser_download_url.*mysys\.tar\.bz2" | cut -d '"' -f 4 | wget -qi -
  tar xjpvf $TAR_FILE
  if [ ! "$?" -eq "0" ] ; then echo "[update] could not untar it" && cd "$_pwd" && return 1; fi
  rm $TAR_FILE

if [ -d "$CLAUDE_FOLDER" ] ; then
    echo "[update] adding coder skill to claude..."
    [ ! -d "$CLAUDE_FOLDER/skills" ] && mkdir -p "$CLAUDE_FOLDER/skills"
    cd "$CLAUDE_FOLDER/skills" && ln -sf "$mysys_folder/agent_docs/skills/coder" "coder"
    cd "$mysys_folder"
  fi  

  cd "$_pwd"
  echo "[update] ...done."
}


# -------------------------------------
usage() {
  echo -n "mysys version: "
  cat "$this_folder/.version"

  cat <<EOM
  usage:
  $(basename $0) { command }

    commands:
      - update: updates 'mysys'
EOM
  exit 1
}

debug "1: $1 2: $2 3: $3 4: $4 5: $5 6: $6 7: $7 8: $8 9: $9"

case "$1" in
  update)
    update
    ;;
  *)
    usage
    ;;
esac