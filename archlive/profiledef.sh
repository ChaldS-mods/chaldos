#!/usr/bin/env bash
# vim: set sw=4 et sts=4 tw=80:
# ChaldOS — archiso profile definition
#
# Builds a hybrid BIOS+UEFI ISO for USB/optical boot.
# Based on current archiso format (v85+).

iso_name="chaldos"
iso_label="CHALDOS_$(date +%Y%m)"
iso_publisher="ChaldOS Project <https://github.com/ChaldS-mods/chaldos>"
iso_application="ChaldOS Gaming Edition v2.0 — Arch Linux based gaming distribution"
iso_version="2.0.0"

install_dir="chaldos"
buildmodes=('iso')
bootmodes=('bios.syslinux' 'uefi.systemd-boot')

pacman_conf="pacman.conf"

airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')

bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')

file_permissions=(
  ["/root"]="0:0:750"
  ["/usr/local/bin/chaldos-mascot"]="0:0:755"
  ["/root/chaldos/install-chaldos.sh"]="0:0:755"
  ["/root/chaldos/post-install.sh"]="0:0:755"
  ["/root/chaldos/davinci-resolve.sh"]="0:0:755"
  ["/root/chaldos/mascot.sh"]="0:0:755"
  ["/root/chaldos/install-libs.sh"]="0:0:755"
)
