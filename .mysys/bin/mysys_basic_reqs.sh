#!/usr/bin/env bash
# shellcheck disable=SC2181,SC1091,SC2034
# -------------------------------
this_folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [ -z "$this_folder" ]; then
  this_folder=$(dirname "$(readlink -f "$0")")
fi
mysys_folder=$(dirname "$this_folder")
env_folder="$mysys_folder/env"
# -------------------------------
. "$this_folder/.include.sh"
# ---------- CONSTANTS ----------

# ---------- FUNCTIONS ----------

sys_basic_reqs_rpi(){
  info "[sys_basic_reqs_rpi|in]"
  
  [ -z "$BASIC_REQS_ALL_VAR" ] && err "[sys_basic_reqs_rpi|out] must provide BASIC_REQS_ALL_VAR env var" && usage
  [ -z "$BASIC_REQS_RPI_VAR" ] && err "[sys_basic_reqs_rpi|out] must provide BASIC_REQS_RPI_VAR env var" && usage
  eval "$BASIC_REQS_ALL_VAR"
  eval "$BASIC_REQS_RPI_VAR"

  sudo apt update
  sudo apt upgrade

  local result=0
  local command

  for app in "${!BASIC_REQS_ALL[@]}"; do
    command="${BASIC_REQS_ALL[$app]}"
    which "$command" >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
      #info "[sys_basic_reqs_linux] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_rpi] adding: $app"
    sudo apt install -y "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_rpi] could not install: $app" && exit 1
	done

  for app in "${!BASIC_REQS_RPI[@]}"; do
    command="${BASIC_REQS_RPI[$app]}"
    which "$command" >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
      info "[sys_basic_reqs_rpi] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_rpi] adding: $app"
    sudo apt install -y "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_rpi] could not install: $app" && exit 1
	done

  info "[sys_basic_reqs_rpi] setting up firewall and unattended upgrades"
  sudo ufw allow ssh        # So you don't lock yourself out!
  sudo ufw allow Samba      # Alternative Samba rule that covers both 445 and 139
  sudo ufw enable || exit 1
  sudo ufw status verbose
  sudo dpkg-reconfigure -plow unattended-upgrades || exit 1

  local msg="[sys_basic_reqs_rpi|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}

sys_basic_reqs_linux(){
  info "[sys_basic_reqs_linux|in]"
  
  [ -z "$BASIC_REQS_ALL_VAR" ] && err "[sys_basic_reqs_linux|out] must provide BASIC_REQS_ALL_VAR env var" && usage
  [ -z "$BASIC_REQS_LINUX_VAR" ] && err "[sys_basic_reqs_linux|out] must provide BASIC_REQS_LINUX_VAR env var" && usage

  eval "$BASIC_REQS_ALL_VAR"
  eval "$BASIC_REQS_LINUX_VAR"

  sudo apt update
  sudo apt -y upgrade
  sudo apt install -y dconf-editor

  local result=0
  local command

  for app in "${!BASIC_REQS_ALL[@]}"; do
    command="${BASIC_REQS_ALL[$app]}"
    which "$command" >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
      #info "[sys_basic_reqs_linux] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_linux] adding: $app"
    sudo apt install -y "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_linux] could not install: $app" && exit 1
	done

  for app in "${!BASIC_REQS_LINUX[@]}"; do
    command="${BASIC_REQS_LINUX[$app]}"
    which "$command" >/dev/null 2>&1
    if [ $? -eq 0 ] ; then
      info "[sys_basic_reqs_linux] $app is already installed - skipping"
      continue
    fi
    info "[sys_basic_reqs_linux] adding: $app"
    sudo apt install -y "$app"
    result="$?"
    [ ! "$result" -eq "0" ] && err "[sys_basic_reqs_linux] could not install: $app" && exit 1
	done

  info "[sys_basic_reqs_linux] setting up firewall and unattended upgrades"
  sudo ufw enable || exit 1
  sudo ufw status verbose
  sudo dpkg-reconfigure -plow unattended-upgrades || exit 1
  
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
  uname -a | grep "rpt-rpi-v8"
  if [ $? -eq 0 ] ; then
    osname="RPT-RPI-V8"
  else
    osname=$(uname)
  fi

  if [[ "$OSTYPE" == "darwin"* ]]; then
  	info "[sys_basic_reqs] running in MACOS"
  	sys_basic_reqs_macos
  elif [ "$osname" == "Linux" ]; then
  	info "[sys_basic_reqs] running in LINUX"
  	sys_basic_reqs_linux
  elif [ "$osname" == "RPT-RPI-V8" ]; then
  	info "[sys_basic_reqs] running in my Raspberry Pi"
  	sys_basic_reqs_rpi
  else
  	err "[sys_basic_reqs|out] as of now not supporting this OS" && exit 1
  fi
  result="$?"
  local msg="[sys_basic_reqs|out] => ${result}"
  [ ! "$result" -eq "0" ] && err "$msg" && exit 1
  info "$msg"
}


# ---------- BASIC REQS ----------

declare -A BASIC_REQS_ALL=( ["curl"]="curl" ["git"]="git" ["wget"]="wget" ["shellcheck"]="shellcheck" ["htop"]="htop" )
BASIC_REQS_ALL_VAR=$(declare -p BASIC_REQS_ALL)
export BASIC_REQS_ALL_VAR

declare -A BASIC_REQS_LINUX=( ["snapd"]="snap" ["vim"]="vim" ["mesa-utils"]="glxinfo" ["rkhunter"]="rkhunter" ["chkrootkit"]="chkrootkit" ["ufw"]="ufw" ["unattended-upgrades"]="unattended-upgrades" )
BASIC_REQS_LINUX_VAR=$(declare -p BASIC_REQS_LINUX)
export BASIC_REQS_LINUX_VAR

declare -A BASIC_REQS_RPI=( ["vim"]="vim" ["rkhunter"]="rkhunter" ["chkrootkit"]="chkrootkit" ["ufw"]="ufw" ["fail2ban"]="fail2ban" ["unattended-upgrades"]="unattended-upgrades" )
BASIC_REQS_RPI_VAR=$(declare -p BASIC_REQS_RPI)
export BASIC_REQS_RPI_VAR

declare -A BASIC_REQS_MACOS
BASIC_REQS_MACOS_VAR=$(declare -p BASIC_REQS_MACOS)
export BASIC_REQS_MACOS_VAR

sys_basic_reqs