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

export MYSYS_FOLDER="$HOME/.mysys"

# ---------- main ----------
info "[bootstrap|in]"

_pwd=$(pwd)

[ ! -d "$MYSYS_FOLDER" ] && mkdir -p "$MYSYS_FOLDER/bin"
cd "$MYSYS_FOLDER/bin" || cd "$_pwd" && exit 1
wget https://raw.githubusercontent.com/jtviegas/mysys/main/.mysys/bin/mysys.sh && \
  chmod +x mysys.sh && \
  ./mysys.sh update

cd "$_pwd"

info "[bootstrap|out]"