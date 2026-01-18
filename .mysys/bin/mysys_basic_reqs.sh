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

# ---------- FUNCTIONS ----------

sys_basic_reqs_linux(){
  info "[sys_basic_reqs_linux|in]"
  
  [ -z "$BASIC_REQS_ALL_VAR" ] && err "[sys_basic_reqs_linux|out] must provide BASIC_REQS_ALL_VAR env var" && usage
  [ -z "$BASIC_REQS_LINUX_VAR" ] && err "[sys_basic_reqs_linux|out] must provide BASIC_REQS_LINUX_VAR env var" && usage

  eval "$BASIC_REQS_ALL_VAR"
  eval "$BASIC_REQS_LINUX_VAR"

  sudo add-apt-repository ppa:kisak/kisak-mesa
  sudo apt update
  sudo apt upgrade
  sudo apt install --install-recommends linux-generic-hwe-24.04
  sudo apt install libcanberra-gtk-module libcanberra-gtk3-module
  sudo apt install --reinstall libdrm-amdgpu1
  sudo apt install --reinstall libdrm-common
  sudo apt install mesa-vulkan-drivers
  sudo usermod -a -G video "$USER"
  sudo usermod -a -G render "$USER"
  sudo apt install dconf-editor

  local result=0
  local command

  for app in "${!BASIC_REQS_ALL[@]}"; do
    command="${BASIC_REQS_ALL[$app]}"
    which "$command" >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ $? -eq 0 ] ; then
      #info "[sys_basic_reqs_linux] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_linux] adding: $app"
    sudo apt install "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_linux] could not install: $app" && exit 1
	done

  for app in "${!BASIC_REQS_LINUX[@]}"; do
    command="${BASIC_REQS_LINUX[$app]}"
    which "$command" >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ $? -eq 0 ] ; then
      #info "[sys_basic_reqs_linux] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_linux] adding: $app"
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
    which "$command" >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ $? -eq 0 ] ; then
      #info "[sys_basic_reqs_macos] $app is already installed - skipping"
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


# ---------- BASIC REQS ----------

declare -A BASIC_REQS_ALL=( ["curl"]="curl" ["git"]="git" ["wget"]="wget" ["shellcheck"]="shellcheck" )
BASIC_REQS_ALL_VAR=$(declare -p BASIC_REQS_ALL)
export BASIC_REQS_ALL_VAR

declare -A BASIC_REQS_LINUX=( ["snapd"]="snap" ["vim"]="vim" ["mesa-utils"]="glxinfo" )
BASIC_REQS_LINUX_VAR=$(declare -p BASIC_REQS_LINUX)
export BASIC_REQS_LINUX_VAR

declare -A BASIC_REQS_MACOS
BASIC_REQS_MACOS_VAR=$(declare -p BASIC_REQS_MACOS)
export BASIC_REQS_MACOS_VAR

sys_basic_reqs