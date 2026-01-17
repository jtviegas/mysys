#!/usr/bin/env bash

# http://bash.cumulonim.biz/NullGlob.html
shopt -s nullglob
# -------------------------------
this_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -z "$this_folder" ]; then
  this_folder=$(dirname "$(readlink -f "$0")")
fi
mysys_folder=$(dirname "$this_folder")
# shellcheck disable=SC2034
env_folder="$mysys_folder/env"
# -------------------------------
# shellcheck disable=SC1091
. "$this_folder/.include.sh"

# ---------- CONSTANTS ----------

export TAR_FILE="mysys.tar.bz2"

# ---------- FUNCTIONS ----------

update(){
  echo "[update|in]"
  _pwd=$(pwd)
  if [ ! -d "$mysys_folder" ]; then
    err "can't find $mysys_folder folder ! sorry I am leaving"
    exit 1
  fi

  cd "$mysys_folder" || exit 1

  curl -L https://api.github.com/repos/jtviegas/mysys/releases/latest | grep "browser_download_url.*mysys\.tar\.bz2" | cut -d '"' -f 4 | wget -qi -
  tar xjpvf $TAR_FILE
   # shellcheck disable=SC2181
  [ ! "$?" -eq "0" ] && err "[update] could not untar it" && cd "$_pwd" && return 1
  rm $TAR_FILE*

  if [ -d "$CLAUDE_FOLDER" ] ; then
    info "[update] claude is here"
    [ ! -d "$CLAUDE_FOLDER/skills" ] && mkdir -p "$CLAUDE_FOLDER/skills"
    cd "$CLAUDE_FOLDER/skills" && ln -sf "$mysys_folder/agent_skills/coder" "coder"
    info "[update] coder skill added to claude"
  fi  

  cd "$_pwd" || exit 1
  echo "[update|out]"
}

update_from_dev_folder(){
  echo "[update_from_dev_folder|in] ($1)"

   [ -z "$1" ] && err "[update_from_dev_folder|out] must provide DEV_FOLDER var" && usage
   local dev_folder="$1"

  _pwd=$(pwd)
  if [ ! -d "$mysys_folder" ]; then
    err "can't find $mysys_folder folder ! sorry I am leaving"
    exit 1
  fi

  cd "$mysys_folder" || exit 1

  cp -r "$dev_folder"/* ./
   # shellcheck disable=SC2181
  [ ! "$?" -eq "0" ] && err "[update_from_dev_folder] could not copy it" && cd "$_pwd" && return 1

  if [ -d "$CLAUDE_FOLDER" ] ; then
    info "[update_from_dev_folder] claude is here"
    [ ! -d "$CLAUDE_FOLDER/skills" ] && mkdir -p "$CLAUDE_FOLDER/skills"
    cd "$CLAUDE_FOLDER/skills" && ln -sf "$mysys_folder/agent_skills/coder" "coder"
    info "[update_from_dev_folder] coder skill added to claude"
  fi  

  cd "$_pwd" || exit 1
  echo "[update_from_dev_folder|out]"
}


ssh_default_key(){
  info "[ssh_default_key|in]"

	local key="id_rsa"
  local result=0
  if [ ! -f "$HOME/.ssh/${key}" ]; then
  	info "creating new ssh key: ${key}"
  	ssh-keygen -t rsa -b 4096 -C "jtviegas@gmail.com" && \
  		eval "$(ssh-agent -s)" && \
  		ssh-add ~/.ssh/${key}
  	 result="$?"
  fi 

  local msg="[ssh_default_key|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}

# -------------------------------------
usage(){
  echo -n "mysys version: "
  cat "$this_folder/.version"

  cat <<EOM
  usage:
  $(basename "$0") { command }

    commands:
      - update:               updates 'mysys'
      - ssh_default_key       creates a default ssh key if none exists
EOM
  exit 1
}

debug "1: $1 2: $2 3: $3 4: $4 5: $5 6: $6 7: $7 8: $8 9: $9"

case "$1" in
  update)
    update
    ;;
  ssh_default_key)
    ssh_default_key
    ;;
  update_from_dev)
    update_from_dev_folder "/home/jtv/code/jtviegas/mysys/.mysys"
    ;;
  *)
    usage
    ;;
esac