# This script provides a bootable install of archlinux with Sway.

clear
echo "   ___           _           _____                       _____          _        _ _ "
echo "  / _ \         | |         /  ___|                     |_   _|        | |      | | | "
echo " / /_\ \_ __ ___| |__ ______\ '--.__      ____ _ _   _    | | _ __  ___| |_ __ _| | | ___ _ __  "
echo " |  _  | '__/ __| '_ \______|'--. \ \ /\ / / _' | | | |   | || '_ \/ __| __/ _' | | |/ _ \ '__| "
echo " | | | | | | (__| | | |     /\__/ /\ V  V / (_| | |_| |  _| || | | \__ \ || (_| | | |  __/ | "
echo " \_| |_/_|  \___|_| |_|     \____/  \_/\_/ \__,_|\__, |  \___/_| |_|___/\__\__,_|_|_|\___|_| "
echo "                                                  __/ | "
echo "                                                 |___/ "
echo ""
echo "        Make sure you red the install.sh file, set variables to the right value, etc."
echo "           Some passwords will be asked to you during the installation process."
echo "                                        WARNING"
echo "This script is not a full automation script; if you don't understand the script you should'nt use it"
echo ""
read -n 1 -s -r -p "Press any key to start the installation ..."

COMPUTER_NAME="arch"
USERNAME="lizcaps"
LVM_PASSOWRD=""
USER_PASSWORD=""
INSTALL_DRIVE="nvme0n1"
DRIVE_NUMERATION_PREFIX="p"
UEFI_SIZE=512
ROOT_SIZE=32
SWAP_SIZE=8
LANGUAGE="en_US.UTF8"
KEYMAP="fr"
COUNTRY_LOCATION="France"
BOX_NAME="Livebox-D3E6"
BOX_PASSWD=""
DATA_REPOSITORY="https://github.com/lizcaps/Home.git"
DATA_INSTALL_FOLDER=".env/Home"
CONFIG_REPOSITORY="https://github.com/lizcaps/asi.git"
CONFIG_FOLDER=".env/asi"


while getopts ":u:lp:p:l:k:cl:cn:id:us:rs:ss:dr:di:cr:cf:" arg; do
  case $arg in
    u) $USERNAME=$OPTARG;;
    lp) $LVM_PASSOWRD=$OPTARG;;
    p) $USER_PASSWORD=$OPTARG;;
    l) $LANGUAGE=$OPTARG;;
    k) $KEYMAP=$OPTARG;;
    cl) $COUNTRY_LOCATION=$OPTARG;;

    cn) $COMPUTER_NAME=$OPTARG;;
    id) $INSTALL_DRIVE=$OPTARG;;
    us) $UEFI_SIZE=$OPTARG;;
    rs) $ROOT_SIZE=$OPTARG;;
    ss) $SWAP_SIZE=$OPTARG;;
    dr) $DATA_REPOSITORY=$OPTARG;;
    di) $DATA_INSTALL_FOLDER=$OPTARG;;
    cr) $CONFIG_REPOSITORY=$OPTARG;;
    cf) $CONFIG_FOLDER=$OPTARG;;

    bn) $BOX_NAME=$OPTARG;;
    bp) $BOX_PASSWD=$OPTARG;;
    esac
done


timedatectl set-ntp true
# -- Create Partition --
sfdisk /dev/"$INSTALL_DRIVE" -uS <<EOF
,$(($UEFI_SIZE*1024*1024/512))
;
EOF
mkfs.fat -F32 /dev/"$INSTALL_DRIVE""$DRIVE_NUMERATION_PREFIX"1
#loading english keyboard to simplify grub core building
loadkeys en
cryptsetup luksFormat /dev/"$INSTALL_DRIVE""$DRIVE_NUMERATION_PREFIX"2
cryptsetup open --type luks /dev/"$INSTALL_DRIVE""$DRIVE_NUMERATION_PREFIX"2 archlv
pvcreate /dev/mapper/archlv
vgcreate archvg /dev/mapper/archlv
lvcreate -L"$SWAP_SIZE"G archvg -n swap
lvcreate -L"$ROOT_SIZE"G archvg -n root
lvcreate -l 100%FREE archvg -n home
mkfs.ext4 /dev/mapper/archvg-root
mkfs.ext4 /dev/mapper/archvg-home
mkswap /dev/mapper/archvg-swap
mount /dev/mapper/archvg-root /mnt
mkdir /mnt/home
mount /dev/mapper/archvg-home /mnt/home
mkdir /mnt/boot
mount -t vfat /dev/"$INSTALL_DRIVE""$DRIVE_NUMERATION_PREFIX"1 /mnt/boot
swapon /dev/mapper/archvg-swap
loadkeys "$KEYMAP"

# -- Install Base Packages --
pacman -Sy reflector
reflector -c "$COUNTRY_LOCATION" -f 12 -l 12 --verbose --save /etc/pacman.d/mirrorlist
pacstrap /mnt base base-devel linux linux-firmware lvm2 \
grub efibootmgr \
wpa_supplicant wireless_tools networkmanager \
pulseaudio openssh openvpn acpilight\
neovim git htop neofetch wget curl noto-fonts man \
sway xorg-server-xwayland swaylock swaybg waybar dmenu pavucontrol \
atom rxvt-unicode firefox-developer-edition discord\
libreoffice-fresh

# -- Generate fstab --
genfstab -U -p /mnt >> /mnt/etc/fstab
sed -i 's|filesystems keyboard|keyboard encrypt lvm2 filesystems|g' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -p linux

# -- Setup Locales --
arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
arch-chroot /mnt hwclock --systohc --utc

sed -i "s|#$LANGUAGE|$LANGUAGE|g" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=$LANGUAGE" > /mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf
echo "$COMPUTER_NAME" > /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1 localhost" >> /mnt/etc/hosts
echo "127.0.0.1 $COMPUTER_NAME.localdomain $COMPUTER_NAME" >> /mnt/etc/hosts

# -- Setup nework with NetworkManager --
arch-chroot /mnt systemctl enable NetworkManager.service
arch-chroot /mnt systemctl disable dhcpcd.service
arch-chroot /mnt systemctl enable wpa_supplicant.service
arch-chroot /mnt systemctl start NetworkManager.service

# -- Grub Install --
sed -i 's|GRUB_CMDLINE_LINUX=""|GRUB_CMDLINE_LINUX="cryptdevice=/dev/'$INSTALL_DRIVE'p2:archvg root=/dev/mapper/archvg-root"|g' /mnt/etc/default/grub
sed -i 's|GRUB_PRELOAD_MODULES="|GRUB_PRELOAD_MODULES="lvm |g' /mnt/etc/default/grub
sed -i 's|#GRUB_ENABLE_CRYPTODISK=y|GRUB_ENABLE_CRYPTODISK=y|g' /mnt/etc/default/grub
sed -i 's|\([[:blank:]]*\)insmod gfxterm|\1insmod gfxterm\n\1insmod gfxterm_background|g' /mnt/etc/grub.d/00_header
echo 'GRUB_BACKGROUND="/boot/grub/themes/background.jpg"' >> /mnt/etc/default/grub
echo 'GRUB_FORCE_HIDDEN_MENU="true"' >> /mnt/etc/default/grub
arch-chroot /mnt chmod a+x /etc/grub.d/31_hold_shift
arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=boot --bootloader-id=grub_uefi --recheck
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
arch-chroot /mnt mkdir /boot/EFI/boot
arch-chroot /mnt cp /boot/EFI/grub_uefi/grubx64.efi /boot/EFI/boot/bootx64.efi

# -- Create new user and setup passwords --
arch-chroot /mnt groupadd sudo
echo "%sudo ALL=(ALL) ALL" >> /mnt/etc/sudoers
arch-chroot /mnt useradd -m -G sudo -s /bin/bash $USERNAME
arch-chroot /mnt su $USERNAME -c "git clone $INSTALL_REPOSITORY /home/'$USERNAME'/'$INSTALL_FOLDER'"
if [ -n "$DATA_INSTALL_FOLDER" && -n "$DATA_REPOSITORY" ]; then
  arch-chroot /mnt su $USERNAME -c "git clone $DATA_REPOSITORY /home/'$USERNAME'/'$DATA_INSTALL_FOLDER'"
fi
arch-chroot /mnt passwd -l root
echo "-- $USERNAME --"
arch-chroot /mnt passwd $USERNAME

# -- Configure --
#arch-chroot /mnt ln -sf /home/"$USERNAME"/"$INSTALL_FOLDER"/home/.zshrc /home/"$USERNAME"/.zshrc
#arch-chroot /mnt ln -sf /home/"$USERNAME"/"$INSTALL_FOLDER"/home/.Xdefaults /home/"$USERNAME"/.Xdefaults
#arch-chroot /mnt ln -sf /home/"$USERNAME"/"$INSTALL_FOLDER"/config /home/"$USERNAME"/.config
#arch-chroot /mnt cp /home/"$USERNAME"/"$INSTALL_FOLDER"/ressources/grubBackground.jpg /boot/grub/themes/background.jpg

echo "     ------ INSTALLATION DONE ------"
echo "You should check if everything went right."
echo "After that, unmount your /mnt and reboot."
echo "-> unmout -R /mnt"
echo "-> reboot"
