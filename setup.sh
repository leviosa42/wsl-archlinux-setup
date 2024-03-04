#!/bin/bash

set -euo pipefail

function print_info() {
  echo -e "\033[36m[INFO] $1\033[0m";
}


: "pre" && {
  ROOT_PASS=${ROOT_PASS:-"password"};

  print_info "pre";
  print_info "    ROOT_PASS: ${ROOT_PASS}";

  echo "root:${ROOT_PASS}" | chpasswd;
}


: "locale" && {
  print_info "locale";

  locale-gen;
  echo "LANG=en_US.UTF-8" > /etc/locale.conf;
}


: "mirrorlist" && {
  COUNTRY="JP";

  print_info "mirrorlist";
  print_info "    COUNTRY: ${COUNTRY}";

  cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup;
  curl -fsSL "https://archlinux.org/mirrorlist/?country=${COUNTRY}&protocol=http&protocol=https&ip_version=4" \
    | sed 's/^#Server/Server/g' \
    | tee /etc/pacman.d/mirrorlist;
}


: "pacman" && {
  print_info "pacman";

  sed -i 's/^#Color/Color/g' /etc/pacman.conf;
  sed -i 's/^#TotalDownload/TotalDownload/g' /etc/pacman.conf;
  echo "ILoveCandy" >> /etc/pacman.conf;
  pacman -Syyu --noconfirm;
  pacman -S --noconfirm \
    base-devel sudo git tree nano vim neovim \
    eza bat ripgrep fd fzf \
    github-cli;
}


: "user" && {
  USER_NAME=${USER_NAME:-"arch"};
  USER_PASS=${USER_PASS:-"password"};
  USER_SHELL=${USER_SHELL:-"/bin/bash"};
  USER_SUDO_NOPASSWD=${USER_SUDO_NOPASSWD:-"false"};
  
  print_info "user";
  print_info "    USER_NAME: ${USER_NAME}";
  print_info "    PASS: ${USER_PASS}";
  print_info "    SHELL: ${USER_SHELL}";
  print_info "    SUDO_NOPASSWD: ${USER_SUDO_NOPASSWD}";


  useradd -m -G wheel -s /bin/bash -d /home/${USER_NAME} ${USER_NAME};
  echo "${USER_NAME}:${USER_PASS}" | chpasswd;
  [ -d /etc/sudoers.d ] && mkdir -p /etc/sudoers.d;
  {
    echo "Defaults lecture=never";
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL";
  } > /etc/sudoers.d/wheel;
}


FEAT_WSL=${FEAT_WSL:-"true"};
: "wsl" && [ "${FEAT_WSL}" = "true" ] && {
  print_info "wsl";

  rm -f /.dockerenv;

  # see: https://learn.microsoft.com/ja-jp/windows/wsl/wsl-config
  {
    echo "[interop]";
    echo "appendWindowsPath = false";
    echo "";
    echo "[user]";
    echo "default = ${USER_NAME}";
  } > /etc/wsl.conf;
}


FEAT_DOTFILES=${FEAT_DOTFILES:-"true"};
: "dotfiles" && [ "${FEAT_DOTFILES}" = "true" ] && {
  DOTFILES_REPO_URL="https://github.com/leviosa42/dotfiles.git";
  DOTFILES_DIR="/home/$USER_NAME/.dotfiles";

  print_info "dotfiles";
  print_info "    DOTFILES_REPO_URL: ${DOTFILES_REPO_URL}";
  print_info "    DOTFILES_DIR: ${DOTFILES_DIR}";

  sudo -H -u $USER_NAME bash -c "git clone ${DOTFILES_REPO_URL} ${DOTFILES_DIR}";
  sudo -H -u $USER_NAME bash -c "cd ${DOTFILES_DIR} && make init link";
}

FEAT_AUR_HELPER=${FEAT_AUR_HELPER:-"true"};
: "aur-helper" && [ "${FEAT_AUR_HELPER}" = "true" ] && {
  AUR_HELPER="paru";
  
  print_info "aur-helper";
  print_info "    AUR_HELPER: ${AUR_HELPER}";

  sudo -H -u $USER_NAME bash -c "git clone https://aur.archlinux.org/${AUR_HELPER}.git /tmp/${AUR_HELPER}";
  sudo -H -u $USER_NAME bash -c "cd /tmp/${AUR_HELPER} && makepkg -si --noconfirm";
  sudo -H -u $USER_NAME bash -c "rm -rf /tmp/${AUR_HELPER}";
}


: "post" && {
  print_info "post";

  if [ "${USER_SUDO_NOPASSWD}" = "true" ]; then
    echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel;
  fi;
}
# vim: set noet ts=2 fdm=marker fmr={,}:
