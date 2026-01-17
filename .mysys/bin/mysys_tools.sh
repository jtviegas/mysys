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

# --- freecad ---
if [ "$osname" == "LINUX" ] ; then
  which freecad >/dev/null 2>&1
  # shellcheck disable=SC2181
  if [ $? -ne 0 ] ; then
    info "[mysys_tools] installing freecad"
    sudo snap install freecad
  fi
fi

