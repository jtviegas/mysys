#!/usr/bin/env bash
# http://bash.cumulonim.biz/NullGlob.html
shopt -s nullglob
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