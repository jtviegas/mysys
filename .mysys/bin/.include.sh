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
