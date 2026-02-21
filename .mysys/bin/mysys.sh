#!/usr/bin/env bash
# -------------------------------
this_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -z "$this_folder" ]; then
  this_folder=$(dirname "$(readlink -f "$0")")
fi
mysys_folder=$(dirname "$this_folder")
# shellcheck disable=SC2034
env_folder="$mysys_folder/env"
# -------------------------------
# -------------------------------
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

# ---------- CONSTANTS ----------
export FILE_VARIABLES=${FILE_VARIABLES:-".variables"}
export FILE_SECRETS=${FILE_SECRETS:-".secrets"}
# -------------------------------
if [ ! -f "$env_folder/$FILE_VARIABLES" ]; then
  warn "we DON'T have a $FILE_VARIABLES variables file - creating it"
  touch "$env_folder/$FILE_VARIABLES"
else
   # shellcheck disable=SC1090
  . "$env_folder/$FILE_VARIABLES"
fi

if [ ! -f "$env_folder/$FILE_SECRETS" ]; then
  warn "we DON'T have a $FILE_SECRETS secrets file - creating it"
  touch "$env_folder/$FILE_SECRETS"
else
   # shellcheck disable=SC1090
  . "$env_folder/$FILE_SECRETS"
fi
# -------------------------------

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

ssh_default_key(){
  info "[ssh_default_key|in] ($1)"

  [ -z "$1" ] && err "[ssh_default_key|out] must provide EMAIL parameter" && exit 
  local EMAIL="$1"
	local key="id_rsa"
  local result=0
  if [ ! -f "$HOME/.ssh/${key}" ]; then
  	info "creating new ssh key: ${key}"
  	ssh-keygen -t rsa -b 4096 -C "$EMAIL" && \
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
      - update:                       updates 'mysys'
      - ssh_default_key <EMAIL>       creates a default ssh key if none exists
EOM
  exit 1
}

debug "1: $1 2: $2 3: $3 4: $4 5: $5 6: $6 7: $7 8: $8 9: $9"

case "$1" in
  update)
    update
    ;;
  ssh_default_key)
    ssh_default_key "$2"
    ;;
  *)
    usage
    ;;
esac