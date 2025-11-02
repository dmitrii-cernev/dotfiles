#!/usr/bin/env bash
# setup-kanata-arch.sh
# Arch Linux: install Kanata and run it as a SYSTEM service using an existing user config ~/.config/kanata/config.kbd.

set -euo pipefail

#---------------------------#
# sanity + identity
#---------------------------#
[[ -f /etc/arch-release ]] || { echo "This script targets Arch Linux. Abort."; exit 1; }

if [[ "${EUID}" -eq 0 ]]; then
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="${SUDO_USER}"
  else
    echo "Run as a regular user with sudo privileges (not as root)."
    exit 1
  fi
else
  TARGET_USER="$(id -un)"
fi

TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
[[ -n "${TARGET_HOME}" && -d "${TARGET_HOME}" ]] || { echo "Cannot resolve home for ${TARGET_USER}. Abort."; exit 1; }

need_sudo() { sudo -v >/dev/null; }
pkg_installed() { pacman -Q "$1" &>/dev/null; }

aur_build_install() {
  need_sudo
  sudo pacman -S --needed --noconfirm base-devel git
  workdir="$(mktemp -d /tmp/kanata-aur.XXXXXX)"
  trap 'rm -rf "${workdir}"' EXIT
  sudo chown -R "${TARGET_USER}:${TARGET_USER}" "${workdir}"
  pushd "${workdir}" >/dev/null
  for aur_pkg in kanata-bin kanata; do
    if sudo -u "${TARGET_USER}" git clone --depth=1 "https://aur.archlinux.org/${aur_pkg}.git"; then
      cd "${aur_pkg}"
      sudo -u "${TARGET_USER}" bash -lc 'makepkg -si --noconfirm --needed'
      popd >/dev/null
      return 0
    fi
  done
  popd >/dev/null
  echo "AUR install failed. Abort."
  exit 1
}

#---------------------------#
# install kanata
#---------------------------#
echo "Installing kanata…"
if pkg_installed kanata; then
  echo "kanata already installed."
else
  if sudo pacman -Sy --needed --noconfirm kanata; then
    echo "kanata installed via pacman."
  else
    echo "Falling back to AUR…"
    aur_build_install
  fi
fi

#---------------------------#
# uinput + input permissions
#---------------------------#
echo "Configuring uinput and input permissions…"
need_sudo
echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
if ! lsmod | grep -q '^uinput'; then
  sudo modprobe uinput || true
fi

if ! getent group uinput >/dev/null; then
  sudo groupadd -r uinput
fi

sudo tee /etc/udev/rules.d/99-uinput.rules >/dev/null <<'RULES'
KERNEL=="uinput", GROUP="uinput", MODE="0660", OPTIONS+="static_node=uinput"
RULES

sudo usermod -aG input,uinput "${TARGET_USER}"
sudo udevadm control --reload
sudo udevadm trigger

#---------------------------#
# verify existing config
#---------------------------#
USER_CFG="${TARGET_HOME}/.config/kanata/config.kbd"
if [[ ! -f "${USER_CFG}" ]]; then
  echo "Error: config file not found at ${USER_CFG}"
  echo "Create ~/.config/kanata/config.kbd before running."
  exit 1
fi

sudo mkdir -p /etc/kanata
sudo cp "${USER_CFG}" /etc/kanata/config.kbd
sudo chmod 0644 /etc/kanata/config.kbd

#---------------------------#
# systemd unit
#---------------------------#
echo "Installing system template unit kanata@.service…"

sudo tee /etc/systemd/system/kanata@.service >/dev/null <<'UNIT'
[Unit]
Description=Kanata keyboard remapper for %i
Documentation=https://github.com/jtroo/kanata
After=systemd-udevd.service
Wants=systemd-udevd.service
ConditionPathExists=/dev/uinput

[Service]
Type=simple
User=%i
Group=%i
SupplementaryGroups=input uinput
ExecStart=/usr/bin/kanata -c /etc/kanata/config.kbd
Restart=on-failure
RestartSec=1
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
DeviceAllow=/dev/uinput rw
DeviceAllow=char-input rw
CapabilityBoundingSet=
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable --now "kanata@${TARGET_USER}.service"

#---------------------------#
# verify
#---------------------------#
sleep 0.5
if systemctl is-active --quiet "kanata@${TARGET_USER}.service"; then
  echo "kanata@${TARGET_USER}.service is active and using ${USER_CFG}."
else
  echo "kanata@${TARGET_USER}.service failed. Inspect logs:"
  echo "  sudo systemctl status kanata@${TARGET_USER}.service --no-pager"
  echo "  sudo journalctl -u kanata@${TARGET_USER}.service -b --no-pager"
  exit 1
fi

echo "Done."

