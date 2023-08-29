#!/usr/bin/env sh

echo "This script is no-op, edit source code to run it."
echo
echo "For your information, it has a very high chance to break your system,"
echo "so make sure you know what you're doing."
echo
echo "Run efibootmgr --help"

# In this example we create efi entry with following:
#
# our boot partition is /dev/sda5, which is specified by --disk and --part
# our label is Arch Linux (can be anything)
# our loader is /boot/vmlinuz-linux
# our root is on /dev/sda6
# our initramfs is /boot/initramfs-linux.img
true efibootmgr \
    --create \
    --disk /dev/sda \
    --part 5 \
    --label "Arch Linux" \
    --loader /vmlinuz-linux \
    --unicode 'root=/dev/sda6 rw initrd=\initramfs-linux.img'
