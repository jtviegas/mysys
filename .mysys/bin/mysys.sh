#!/usr/bin/env bash

# ===> COMMON SECTION START  ===>

# http://bash.cumulonim.biz/NullGlob.html
shopt -s nullglob
# -------------------------------
this_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -z "$this_folder" ]; then
  this_folder=$(dirname "$(readlink -f "$0")")
fi
mysys_folder=$(dirname "$this_folder")
env_folder="$mysys_folder/env"
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
export SYS_VARIABLES=${SYS_VARIABLES:-".sys_variables"}
export FILE_VARIABLES=${FILE_VARIABLES:-".variables"}
export FILE_SECRETS=${FILE_SECRETS:-".secrets"}
export TAR_FILE="mysys.tar.bz2"
# -------------------------------
if [ ! -f "$env_folder/$SYS_VARIABLES" ]; then
  warn "we DON'T have a $SYS_VARIABLES variables file - creating it"
  touch "$env_folder/$SYS_VARIABLES"
else
   # shellcheck disable=SC1090
  . "$env_folder/$SYS_VARIABLES"
fi

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

# ---------- BASIC REQS ----------

declare -A BASIC_REQS_ALL=( ["curl"]="curl" ["git"]="git" ["wget"]="wget" ["shellcheck"]="shellcheck" )
export BASIC_REQS_ALL_VAR=$(declare -p BASIC_REQS_ALL)


declare -A BASIC_REQS_LINUX=( ["snapd"]="snap" ["vim"]="vim" )
export BASIC_REQS_LINUX_VAR=$(declare -p BASIC_REQS_LINUX)

declare -A BASIC_REQS_MACOS
export BASIC_REQS_MACOS_VAR=$(declare -p BASIC_REQS_MACOS)

sys_basic_reqs_linux(){
  info "[sys_basic_reqs_linux|in]"
  
  [ -z "$BASIC_REQS_ALL_VAR" ] && err "[sys_basic_reqs_linux|out] must provide BASIC_REQS_ALL_VAR env var" && usage
  [ -z "$BASIC_REQS_LINUX_VAR" ] && err "[sys_basic_reqs_linux|out] must provide BASIC_REQS_LINUX_VAR env var" && usage

  eval "$BASIC_REQS_ALL_VAR"
  eval "$BASIC_REQS_LINUX_VAR"

  local result=0
  local command

  for app in "${!BASIC_REQS_ALL[@]}"; do
    command="${BASIC_REQS_ALL[$app]}"
    $(which "$command" >/dev/null 2>&1)
    if [ $? -eq 0 ] ; then
      info "[sys_basic_reqs_linux] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_linux] adding: $app"
    sudo apt install "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_linux] could not install: $app" && exit 1
	done

  for app in "${!BASIC_REQS_LINUX[@]}"; do
    command="${BASIC_REQS_LINUX[$app]}"
    $(which "$command" >/dev/null 2>&1)
    if [ $? -eq 0 ] ; then
      info "[sys_basic_reqs_linux] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_linux] adding: $command"
    sudo apt install "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_linux] could not install: $app" && exit 1
	done
  
  local msg="[sys_basic_reqs_linux|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}

sys_basic_reqs_macos(){
  info "[sys_basic_reqs_macos|in]"

  [ -z "$BASIC_REQS_ALL_VAR" ] && err "[sys_basic_reqs_macos|out] must provide BASIC_REQS_ALL_VAR env var" && usage
  [ -z "$BASIC_REQS_MACOS_VAR" ] && err "[sys_basic_reqs_macos|out] must provide BASIC_REQS_MACOS_VAR env var" && usage

  eval "$BASIC_REQS_ALL_VAR"
  eval "$BASIC_REQS_MACOS_VAR"

  local result=0
  local command
  
  for app in "${!BASIC_REQS_ALL[@]}"; do
    command="${BASIC_REQS_ALL[$app]}"
    $(which "$command" >/dev/null 2>&1)
    if [ $? -eq 0 ] ; then
      info "[sys_basic_reqs_macos] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_macos] adding: $app"
    brew install "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_macos] could not install: $app" && exit 1
	done

  local msg="[sys_basic_reqs_macos|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}

sys_basic_reqs(){
  info "[sys_basic_reqs|in]"
  
  local osname
  osname=$(uname)
  if [[ "$OSTYPE" == "darwin"* ]]; then
  	info "[sys_basic_reqs] running in MACOS"
  	sys_basic_reqs_macos
  elif [ "$osname" == "Linux" ]; then
  	info "[sys_basic_reqs] running in LINUX"
  	sys_basic_reqs_linux
  else
  	err "[sys_basic_reqs|out] as of now not supporting this OS" && exit 1
  fi
  result="$?"
  local msg="[sys_basic_reqs|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}



# ---------- FUNCTIONS ----------

update(){
  echo "[update] ..."

  _pwd=$(pwd)

  if [ ! -d "$mysys_folder" ]; then
    err "can't find $mysys_folder folder ! sorry I am leaving"
    exit 1
  fi

  cd "$mysys_folder" || exit 1

  curl -L https://api.github.com/repos/jtviegas/mysys/releases/latest | grep "browser_download_url.*mysys\.tar\.bz2" | cut -d '"' -f 4 | wget -qi -
  #tar xjpvf $TAR_FILE
  if tar xjpvf $TAR_FILE ; then echo "[update] could not untar it" && cd "$_pwd" && return 1; fi
  rm $TAR_FILE

if [ -d "$CLAUDE_FOLDER" ] ; then
  info "[update] claude is here"
  [ ! -d "$CLAUDE_FOLDER/skills" ] && mkdir -p "$CLAUDE_FOLDER/skills"
  cd "$CLAUDE_FOLDER/skills" && ln -sf "$mysys_folder/agent_docs/skills/coder" "coder"
  info "[update] coder skill added to claude"
fi  

  cd "$_pwd" || exit 1
  echo "[update] ...done."
}


sys_reqs(){
  info "[sys_reqs|in]"

   local osname
   osname=$(uname)
  if [[ "$OSTYPE" == "darwin"* ]]; then
  	info "[sys_reqs] running in MACOS"
  	sys_reqs_macos
  elif [ "$osname" == "Linux" ]; then
  	info "[sys_reqs] running in LINUX"
  	sys_reqs_linux
  else
  	err "[sys_reqs|out] can't support this OS" && exit 1
  fi
  result="$?"
  local msg="[sys_reqs|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}

sys_reqs_linux(){
  info "[sys_reqs_linux|in]"
  
  [ -z "$SYS_REQS_LINUX" ] && err "[sys_reqs_linux|out] must provide SYS_REQS_LINUX env var" && usage
  
  local result=0
  info "[sys_reqs_linux] adding: vscode"
	sudo snap install --classic code
	result="$?"
  [ ! "$result" -eq "0" ] && err "[sys_reqs_linux|out] could not install: vscode" && exit 1

  for app in $SYS_REQS_LINUX; do
    info "[sys_reqs_linux] adding: $app"
    [ "$app" == "code" ] && continue
    sudo apt install "$app" 
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_reqs_linux|out] could not install: $app" && exit 1
	done
  
  local msg="[sys_reqs_linux|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}

sys_reqs_macos(){
  info "[sys_reqs_macos|in]"
  
  [ -z "$SYS_REQS_MACOS" ] && err "[sys_reqs_macos|out] must provide SYS_REQS_MACOS env var" && usage
  local result=0
  for app in $SYS_REQS_MACOS; do
    info "[sys_reqs_macos] adding: $app"
    sudo apt install "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_reqs_macos|out] could not install: $app" && exit 1
	done
  
  local msg="[sys_reqs_macos|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
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
      - sys_basic_reqs				installs basic sys requirements
      - sys_reqs							installs other sys requirements
      - ssh_default_key       creates a default ssh key if none exists
EOM
  exit 1
}

debug "1: $1 2: $2 3: $3 4: $4 5: $5 6: $6 7: $7 8: $8 9: $9"

case "$1" in
  update)
    update
    ;;
  sys_basic_reqs)
    sys_basic_reqs
    ;;
  sys_reqs)
    sys_reqs
    ;;
  ssh_default_key)
    ssh_default_key
    ;;
  *)
    usage
    ;;
esac