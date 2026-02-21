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


if [ "$(uname)" != "Linux" ]; then
  err "[mysys_tools_linux] this script can only run on a Linux OS" && exit 1
else
  uname -a | grep "rpt-rpi-v8"
  [ $? -eq 0 ] && err "[mysys_tools_linux] this script can not run on my Raspberry Pi" && exit 1
fi

# ---------- main ----------
info "[mysys_tools_linux|in]"

sudo apt update && sudo apt install ca-certificates

which freecad >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing freecad"
  sudo snap install freecad
fi

which uv >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

which foliate >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing foliate"
  sudo add-apt-repository ppa:apandada1/foliate && \
    sudo apt update && \
      sudo apt install foliate
fi

which surfshark >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing surfshark"
  sudo snap install surfshark
fi

which sdk >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing sdkman"
  curl -s "https://get.sdkman.io" | bash
fi

which xclip >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing xclip"
  sudo apt install xclip
fi

which hf >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing hf"
  curl -LsSf https://hf.co/cli/install.sh | bash
fi

which cc >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing gcc"
  sudo apt install gcc
fi

which docker >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_linux] installing docker"
  sudo apt remove "$(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc | cut -f1)"
  # Add Docker's official GPG key:
  sudo apt update
  sudo apt install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # Add the repository to Apt sources:
  sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo groupadd docker
  sudo usermod -aG docker "$USER"

fi


info "[mysys_tools_linux|out]"