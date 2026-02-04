#!/usr/bin/env bash
# shellcheck disable=SC2181,SC1091,SC2034

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
. "$this_folder/.include.sh"

# ---------- CONSTANTS ----------

export TAR_FILE="mysys.tar.bz2"

# ---------- FUNCTIONS ----------


# ---------- find system OS ----------

osname=$(uname)
if [[ "$OSTYPE" == "darwin"* ]]; then
  info "[mysys_tools] running in MACOS"
  osname="MACOS"
elif [ "$osname" == "Linux" ]; then
  info "[mysys_tools] running in LINUX"
  osname="LINUX"
else
  err "[mysys_tools] as of now not supporting this OS" && exit 1
fi

# ---------- main ----------
info "[mysys_tools|in]"

if [ "$osname" == "LINUX" ] ; then

  which freecad >/dev/null 2>&1
  if [ $? -ne 0 ] ; then
    info "[mysys_tools] installing freecad"
    sudo snap install freecad
  fi

  which uv >/dev/null 2>&1
  if [ $? -ne 0 ] ; then
    info "[mysys_tools] installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
  fi

  which foliate >/dev/null 2>&1
  if [ $? -ne 0 ] ; then
    info "[mysys_tools] installing foliate"
    sudo add-apt-repository ppa:apandada1/foliate && \
      sudo apt update && \ 
      sudo apt install foliate
  fi

  which surfshark >/dev/null 2>&1
  if [ $? -ne 0 ] ; then
    info "[mysys_tools] installing surfshark"
    sudo snap install surfshark
  fi

  which sdk >/dev/null 2>&1
  if [ $? -ne 0 ] ; then
    info "[mysys_tools] installing sdkman"
    curl -s "https://get.sdkman.io" | bash
  fi

fi

info "[mysys_tools|out]"