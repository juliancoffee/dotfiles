#!/usr/bin/env sh

if [ -n "$PARTITION" ]
then
efibootmgr \
    --create \
    --disk /dev/sda \
    --part "${PARTITION:?please specify \$PARTITION variable}" \
    --label "Arch Linux (LTS)" \
    --loader /vmlinuz-linux \
    --unicode 'root=/dev/sda6 rw initrd=\initramfs-linux.img'
else
    echo "PARTITION variable is unset."
fi
