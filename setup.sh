#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gum
set -euo pipefail

[[ "$EUID" -eq 0 ]] || { echo "This script must be run as root"; exit 1; }

clear
export GUM_INPUT_HEADER_FOREGROUND=99
export GIT_HTTP_LOW_SPEED_LIMIT=1
export GIT_HTTP_LOW_SPEED_TIME=600

USERNAME="$(gum input --header 'Username:')"
USERNAME="${USERNAME,,}"

EMAIL="$(gum input --header 'Email:')"
EMAIL="${EMAIL,,}"

PASS="$(gum input --password --header 'Passphrase:')"
PASS_VERIFY="$(gum input --password --header 'Verify passphrase:')"

[[ "$PASS" == "$PASS_VERIFY" ]] || { echo "Passphrases do not match"; exit 1; }

DISK="$(lsblk -dnpo NAME,SIZE,TYPE \
  | grep 'disk' \
  | gum choose --header 'Select disk:' \
  | awk '{ print $1 }')"

gum confirm "This is a destructive action. Continue?" || exit 1

if [[ "$DISK" =~ nvme ]]; then
  ESP="${DISK}p1"
  ROOT="${DISK}p2"
else
  ESP="${DISK}1"
  ROOT="${DISK}2"
fi

parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP 1MiB 2GiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart ROOT 2GiB 100%
partprobe "$DISK"
udevadm settle

mkfs.fat -F 32 -n BOOT "$ESP"

printf '%s' "$PASS" | cryptsetup luksFormat -q "$ROOT" -
printf '%s' "$PASS" | cryptsetup open "$ROOT" enc -
unset PASS PASS_VERIFY

mkfs.ext4 -L NIX /dev/mapper/enc

mount -t tmpfs -o mode=755 none /mnt
mkdir /mnt/{boot,nix}
mount -o umask=0077 "$ESP" /mnt/boot
mount /dev/mapper/enc /mnt/nix
mkdir -p /mnt/nix/persist/.system

nixos-generate-config --root /mnt

git clone https://github.com/1-x0/.files /mnt/nix/persist/.files

cp /mnt/etc/nixos/hardware-configuration.nix /mnt/nix/persist/.files/
sed -i '/fsType = "tmpfs";/a\      options = [ "mode=755" ];' /mnt/nix/persist/.files/hardware-configuration.nix
git -C /mnt/nix/persist/.files add -f hardware-configuration.nix

cp /mnt/nix/persist/.files/constants.nix.example /mnt/nix/persist/.files/constants.nix
sed -i "s/__USERNAME__/$USERNAME/" /mnt/nix/persist/.files/constants.nix
sed -i "s/__EMAIL__/$EMAIL/" /mnt/nix/persist/.files/constants.nix
git -C /mnt/nix/persist/.files add -f constants.nix

nixos-install --root /mnt --flake /mnt/nix/persist/.files#nixos --no-root-passwd

echo "Rebooting in 5 seconds"
sleep 5
reboot
