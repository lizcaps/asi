# arch-sway
complete arch install script.
UEFI, Encryption, Sway, Waybar, zsh, urxvt ...
This script is not configurable, so you should edit it to meet your needs.

## Install method
 get an archlinux iso at https://www.archlinux.org/download/
 make a bootable usb key with
 >dd bs=4M if=/path/to/archlinux.iso of=/dev/sdx status=progress && sync

 pull this repo and execute install.sh after reading the file.
Make sure the variables are set to the right values for you. You can set it at runtime, with a config file or with inline parameters:

exemple with curl :

> curl -L "https://github.com/lizcaps/arch-sway/blob/master/install.h" | bash -s -- -cn "arch-computer" -u "lizcaps" -p "my-secure-password" -id "nvme0n1"

- -cn COMPUTER_NAME="arch-pc" : the name of the computer.
- -u  USERNAME="username" : the name of the user. uppercase on first letter is not a good idea.
- -lp LVM_PASSWORD="" : your LVM password
- -p  USER_PASSWORD="" : the password of your user account.
- -id INSTALL_DRIVE=nvme0n1 : the drive to use for your install
- -us UEFI_SIZE=512 : the size (in MB) of your UEFI Partition.
- -rs ROOT_SIZE=32 : the size (in GB) of your root partition.
- -ss SWAP_SIZE=2 : the size (in GB) of your swap.
- -l  LANGUAGE="en_US.UTF8" : your operating system language.
- -k  KEYMAP="fr" : the keyboard you want to use.
- -cl COUNTRY_LOCATION="France" : your country location (to make pacman faster).
- -dr DATA_REPOSITORY="" : if you have a data repository, you can put it here to download it at install.
- -di DATA_INSTALL_FOLDER=".distantHome" : the location of your data repository, in ~/
- -cr CONFIG_REPOSITORY="https://github.com/lizcaps/arch-sway.git" : the .config you want to use. default to this config.
- -cf CONFIG_FOLDER=".asi" : the folder where you want to put the config from git.

there is no root password; since you have sudo and a user, root is not needed and is disabled
