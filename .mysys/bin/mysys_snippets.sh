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


# ---------- main ----------
info "[mysys_snippets|in]"

cat <<-EOF

  check processes:
    ps -ef
    htop

  check cron:
    sudo cat /etc/crontab
    sudo crontab -l

  check for active connections:
    sudo ss -tulpn

  check for compromises:
    sudo chkrootkit
    sudo rkhunter --check

  make curls calls avoiding dns cache
    curl -H "Cache-Control: no-cache" -H "Pragma: no-cache" ".......?t=$(date +%s)"

EOF


info "[mysys_snippets|out]"