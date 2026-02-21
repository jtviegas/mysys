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

export TAR_FILE="mysys.tar.bz2"

# ---------- FUNCTIONS ----------


# ---------- find system OS ----------

uname -a | grep "rpt-rpi-v8"
# shellcheck disable=SC2181
if [ $? -ne 0 ] ; then
   err "[mysys_tools_rpi] this script can only run on my Raspberry Pi" && exit 1
fi


# ---------- main ----------
info "[mysys_tools_rpi|in]"

info "[mysys_tools_rpi] if you want to install a samba share do export variable SAMBA_DISK and MOUNT_POINT and re-run this script"
info "[mysys_tools_rpi] examples: SAMBA_DISK=/dev/sda1 MOUNT_POINT=/mnt/share"

sudo apt update && sudo apt install -y ca-certificates

which docker >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_rpi] installing docker"
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo groupadd docker
  sudo usermod -aG docker "$USER"
  docker info | grep -i "architecture"
  docker run hello-world
  echo '{"log-driver": "json-file","log-opts":{"max-size": "10m","max-file": "3"}}' | sudo tee /etc/docker/daemon.json
  sudo systemctl restart docker
fi

which node >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_rpi] installing nodejs"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt install -y nodejs
fi

which claude >/dev/null 2>&1
if [ $? -ne 0 ] ; then
  info "[mysys_tools_rpi] installing claude"
  curl -fsSL https://claude.ai/install.sh | bash
fi

if [ -n "$SAMBA_DISK" ] && [ -n "$MOUNT_POINT" ]; then
  info "[mysys_tools_rpi] installing samba"
  disk_id=$(sudo blkid "$SAMBA_DISK" | grep -Po ' UUID="\K[^"]+')
  fstype=$(sudo blkid -o value -s TYPE "$SAMBA_DISK")
  info "[mysys_tools_rpi] disk id: $disk_id"
  sudo mkdir -p "$MOUNT_POINT"
  sudo chown "$USER:$USER" "$MOUNT_POINT"
  sudo chmod -R 777 "$MOUNT_POINT"
  sudo cp /etc/fstab /etc/fstab.bak
  echo "UUID=$disk_id $MOUNT_POINT $fstype defaults,user,rw,nofail,uid=1000,gid=1000,umask=000  0  0" | sudo tee -a /etc/fstab
  sudo mount -a
  sudo apt update
  sudo apt install samba samba-common-bin -y
  # define samba share
  sudo tee -a /etc/samba/smb.conf <<EOF
[samba]
   path = ${MOUNT_POINT}
   writeable = yes
   browseable = yes
   public = yes
   guest ok = yes
   guest only = yes
   force user = ${USER}
EOF
  sudo systemctl restart smbd


fi



info "[mysys_tools_rpi|out]"