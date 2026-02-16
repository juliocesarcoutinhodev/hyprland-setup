#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || pwd)"
BASE_DIR="$SCRIPT_DIR"
DOTFILES_DIR="$BASE_DIR/dotfiles"
BACKUP_DIR="$HOME/.local/state/hyprland-setup/backup-$(date +%Y%m%d-%H%M%S)"
TMP_REPO_DIR=""

PACMAN_BOOTSTRAP=(base-devel git curl)

PACMAN_BASE_PACKAGES=(
  hyprland hypridle hyprlock hyprpaper hyprpicker xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar wofi swaync wlogout swww
  wl-clipboard cliphist wtype grim slurp satty jq python-gobject libnotify
  kitty nemo mission-center gnome-calculator pavucontrol
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber playerctl
  gnome-keyring polkit-gnome qt6ct noto-fonts ttf-jetbrains-mono-nerd brightnessctl
  networkmanager network-manager-applet bluez bluez-utils blueman
  zsh zsh-autosuggestions zsh-syntax-highlighting fastfetch fzf starship
  nodejs npm
  jdk21-openjdk jre21-openjdk
  jdk25-openjdk jre25-openjdk
)

AUR_PACKAGES=(
  catppuccin-cursors-mocha
  catppuccin-gtk-theme-mocha
  zen-browser-bin
  visual-studio-code-bin
)

log() {
  printf '[hyprland-setup] %s\n' "$*"
}

warn() {
  printf '[hyprland-setup][WARN] %s\n' "$*"
}

cleanup() {
  if [ -n "$TMP_REPO_DIR" ] && [ -d "$TMP_REPO_DIR" ]; then
    rm -rf "$TMP_REPO_DIR"
  fi
}
trap cleanup EXIT

ensure_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    log "Este script foi feito para Arch Linux (pacman)."
    exit 1
  fi
}

ensure_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    log "sudo nao encontrado. Instale sudo e rode novamente."
    exit 1
  fi
  sudo -v
}

pacman_install_missing() {
  local -a desired=("$@")
  local -a available=()
  local -a missing=()

  for pkg in "${desired[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
      continue
    fi
    if pacman -Si "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if ((${#missing[@]} > 0)); then
    warn "Pacotes nao encontrados nos repos oficiais (ignorados): ${missing[*]}"
  fi

  if ((${#available[@]} > 0)); then
    log "Instalando pacotes oficiais: ${available[*]}"
    sudo pacman -S --needed --noconfirm "${available[@]}"
  else
    log "Pacotes oficiais ja estao instalados."
  fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  log "yay nao encontrado. Instalando yay automaticamente..."
  pacman_install_missing "${PACMAN_BOOTSTRAP[@]}"

  local build_dir
  build_dir="$(mktemp -d /tmp/yay-build-XXXXXX)"

  git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
  (
    cd "$build_dir/yay"
    makepkg -si --noconfirm
  )

  rm -rf "$build_dir"
}

aur_install_missing() {
  local -a desired=("$@")
  local -a available=()
  local -a missing=()

  for pkg in "${desired[@]}"; do
    if yay -Qq "$pkg" >/dev/null 2>&1; then
      continue
    fi
    if yay -Si "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if ((${#missing[@]} > 0)); then
    warn "Pacotes AUR nao encontrados (ignorados): ${missing[*]}"
  fi

  if ((${#available[@]} > 0)); then
    log "Instalando pacotes AUR: ${available[*]}"
    yay -S --needed --noconfirm --answerclean None --answerdiff None --removemake "${available[@]}"
  else
    log "Pacotes AUR ja estao instalados."
  fi
}

ensure_dotfiles_available() {
  if [ -d "$DOTFILES_DIR/.config/hypr" ]; then
    return
  fi

  local repo_url="${HYPR_SETUP_REPO:-}"
  if [ -z "$repo_url" ]; then
    log "Dotfiles nao encontrados ao lado do script."
    log "Defina HYPR_SETUP_REPO para clonar automaticamente o repositorio com os dotfiles."
    log "Exemplo: HYPR_SETUP_REPO='https://github.com/seu-usuario/hyprland-setup.git' bash install.sh"
    exit 1
  fi

  log "Clonando repositorio de dotfiles: $repo_url"
  pacman_install_missing "${PACMAN_BOOTSTRAP[@]}"

  TMP_REPO_DIR="$(mktemp -d /tmp/hyprland-setup-XXXXXX)"
  git clone --depth 1 "$repo_url" "$TMP_REPO_DIR"

  BASE_DIR="$TMP_REPO_DIR"
  DOTFILES_DIR="$BASE_DIR/dotfiles"

  if [ ! -d "$DOTFILES_DIR/.config/hypr" ]; then
    log "Repositorio clonado, mas estrutura dotfiles invalida: $DOTFILES_DIR"
    exit 1
  fi
}

backup_path_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local rel="${target#$HOME/}"
    local dst="$BACKUP_DIR/$rel"
    mkdir -p "$(dirname "$dst")"
    mv "$target" "$dst"
    log "Backup: $target -> $dst"
  fi
}

restore_dir() {
  local src="$1"
  local dst="$2"

  if [ ! -e "$src" ]; then
    warn "Origem nao encontrada, pulando restore: $src"
    return
  fi

  backup_path_if_exists "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  log "Restaurado: $dst"
}

restore_files() {
  log "Criando backup local em: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"

  restore_dir "$DOTFILES_DIR/.config/hypr" "$HOME/.config/hypr"
  restore_dir "$DOTFILES_DIR/.config/waybar" "$HOME/.config/waybar"
  restore_dir "$DOTFILES_DIR/.config/wofi" "$HOME/.config/wofi"
  restore_dir "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
  restore_dir "$DOTFILES_DIR/.config/swaync" "$HOME/.config/swaync"
  restore_dir "$DOTFILES_DIR/.icons/Catppuccin-Mocha-new" "$HOME/.icons/Catppuccin-Mocha-new"

  mkdir -p "$HOME/Imagens/Wallpapers" "$HOME/Imagens/Screenshots"
  if [ -d "$DOTFILES_DIR/Imagens/Wallpapers" ]; then
    cp -a "$DOTFILES_DIR/Imagens/Wallpapers/." "$HOME/Imagens/Wallpapers/"
    log "Wallpapers restaurados."
  fi

  chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
}

normalize_paths() {
  local files=(
    "$HOME/.config/hypr/hyprland.conf"
    "$HOME/.config/hypr/hyprlock.conf"
    "$HOME/.config/hypr/hyprpaper.conf"
  )

  for f in "${files[@]}"; do
    if [ -f "$f" ]; then
      sed -i "s|/home/julio/|$HOME/|g" "$f"
    fi
  done
}

apply_theme_defaults() {
  if command -v gsettings >/dev/null 2>&1; then
    log "Aplicando tema GTK/cursor/icon via gsettings"
    gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-sky-cursors" || true
    gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-sky-standard+default" || true
    gsettings set org.gnome.desktop.interface icon-theme "Catppuccin-Mocha-new" || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" || true
  fi
}

configure_services() {
  if systemctl list-unit-files | grep -q '^NetworkManager\.service'; then
    sudo systemctl enable --now NetworkManager || true
  fi
  if systemctl list-unit-files | grep -q '^bluetooth\.service'; then
    sudo systemctl enable --now bluetooth || true
  fi
}

configure_java_default() {
  if command -v archlinux-java >/dev/null 2>&1; then
    if archlinux-java status | grep -q 'java-25-openjdk'; then
      sudo archlinux-java set java-25-openjdk || true
    elif archlinux-java status | grep -q 'java-21-openjdk'; then
      sudo archlinux-java set java-21-openjdk || true
    fi
  fi
}

post_checks() {
  log "Resumo de comandos criticos:"
  local cmds=(
    hyprland hyprctl hypridle hyprlock waybar wofi swww swaync
    wl-paste cliphist wl-copy wtype grim slurp satty jq playerctl
    wpctl brightnessctl pavucontrol wlogout missioncenter nemo kitty zen-browser
    gnome-calculator code java javac node npm npx
  )

  for c in "${cmds[@]}"; do
    if command -v "$c" >/dev/null 2>&1; then
      printf '  [ok] %s\n' "$c"
    else
      printf '  [!!] faltando: %s\n' "$c"
    fi
  done
}

main() {
  ensure_arch
  ensure_sudo

  pacman_install_missing "${PACMAN_BOOTSTRAP[@]}"
  ensure_yay
  ensure_dotfiles_available

  pacman_install_missing "${PACMAN_BASE_PACKAGES[@]}"
  aur_install_missing "${AUR_PACKAGES[@]}"

  restore_files
  normalize_paths
  apply_theme_defaults
  configure_services
  configure_java_default
  post_checks

  log "Concluido. Reinicie ou faça logout/login para aplicar tudo no Hyprland."
}

main "$@"
