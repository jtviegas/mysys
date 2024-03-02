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
# -------------------------------
if [ ! -f "$mysys_folder/$FILE_VARIABLES" ]; then
  warn "we DON'T have a $FILE_VARIABLES variables file - creating it"
  touch "$mysys_folder/$FILE_VARIABLES"
else
  . "$mysys_folder/$FILE_VARIABLES"
fi

if [ ! -f "$mysys_folder/$FILE_SECRETS" ]; then
  warn "we DON'T have a $FILE_SECRETS secrets file - creating it"
  touch "$mysys_folder/$FILE_SECRETS"
else
  . "$mysys_folder/$FILE_SECRETS"
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

  curl -L https://api.github.com/repos/jtviegas-sandbox/mysys/releases/latest | grep "browser_download_url.*mysys\.tar\.bz2" | cut -d '"' -f 4 | wget -qi -
  tar xjpvf $TAR_FILE
  if [ ! "$?" -eq "0" ] ; then echo "[update] could not untar it" && cd "$_pwd" && return 1; fi
  rm $TAR_FILE

  cd "$_pwd"
  echo "[update] ...done."
}

release(){
  info "[release] ..."
  _pwd=`pwd`
  cd "$mysys_folder"

  tar cjpvf "$TAR_FILE" "include" "bin"
  if [ ! "$?" -eq "0" ] ; then err "[release] could not tar it" && cd "$_pwd" && return 1; fi
  ls -altr
  cd "$_pwd"
  info "[release] ...done."
}

config(){
  info "[config] ..."
  _pwd=`pwd`

  cd ~/

  if [ ! -f ".pypirc" ] && [ ! -z "$PYPI_TOKEN" ]; then
    info "[config] no '.pypirc' going to create it"
    echo "[pypi]" > .pypirc
    echo "username = __token__" >> .pypirc
    echo "password = $PYPI_TOKEN" >> .pypirc
  fi

  cd "$_pwd"
  info "[config] ...done."
}





# -------------------------------------
usage() {
  cat <<EOM
  usage:
  $(basename $0) { command }

    commands:
      - update: updates 'mysys'
      - release: packages mysys into a tar for release purposes
      - config: adds several system configurations
                  - .pypirc
                  - ...
EOM
  exit 1
}

debug "1: $1 2: $2 3: $3 4: $4 5: $5 6: $6 7: $7 8: $8 9: $9"

case "$1" in
  update)
    update
    ;;
  release)
    release
    ;;
  config)
    config
    ;;
  *)
    usage
    ;;
esac