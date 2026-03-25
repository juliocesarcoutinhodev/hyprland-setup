#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$BASE_DIR/dotfiles"
MANIFEST_DIR="$BASE_DIR/manifests"
INVENTORY_DIR="$BASE_DIR/inventory"
ASSETS_DIR="$BASE_DIR/assets/webapps/icons"
STAMP_DIR="$BASE_DIR/backups/snapshot-$(date +%Y%m%d-%H%M%S)"
SUDO_AVAILABLE=0

HOME_PATHS=(
  .config/hypr
  .config/waybar
  .config/waybar-pills
  .config/wofi
  .config/kitty
  .config/wlogout
  .config/btop
  .config/cava
  .config/satty
  .config/gtk-3.0
  .config/gtk-4.0
  .config/xsettingsd
  .config/fastfetch
  .config/nvim
  .config/Code/User/settings.json
  .config/Code/User/keybindings.json
  .config/starship.toml
  .config/mimeapps.list
  .local/bin
  .local/share/applications
  .icons/Catppuccin-Mocha-new
  Imagens/Wallpapers
  .zshrc
  .gtkrc-2.0
)

ROOT_PATHS=(
  /etc/sddm.conf
  /etc/mkinitcpio.conf
  /etc/plymouth/plymouthd.conf
  /etc/systemd/network
  /etc/systemd/zram-generator.conf
)

log() {
  printf '[hyprland-backup] %s\n' "$*"
}

warn() {
  printf '[hyprland-backup][WARN] %s\n' "$*"
}

ensure_dirs() {
  mkdir -p "$DOTFILES_DIR" "$MANIFEST_DIR" "$INVENTORY_DIR" "$ASSETS_DIR"
}

snapshot_existing_repo_path() {
  local dst="$1"
  local rel_dst

  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    return
  fi

  rel_dst="${dst#$BASE_DIR/}"
  mkdir -p "$STAMP_DIR/$(dirname "$rel_dst")"
  cp -a "$dst" "$STAMP_DIR/$rel_dst"
}

copy_home_path() {
  local rel="$1"
  local src="$HOME/$rel"
  local dst="$DOTFILES_DIR/$rel"

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    warn "Path home nao encontrado, pulando: $src"
    return
  fi

  snapshot_existing_repo_path "$dst"
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"

  if [ "$rel" = ".config/Code/User/settings.json" ]; then
    sed -i '/"yaml.schemas"/,+2d' "$dst"
  fi

  log "Snapshot home: $src -> $dst"
}

copy_root_path() {
  local src="$1"
  local rel="${src#/}"
  local dst="$DOTFILES_DIR/$rel"

  if [ ! -e "$src" ] && [ ! -L "$src" ] && [ "$SUDO_AVAILABLE" -ne 1 ]; then
    warn "Path root nao encontrado, pulando: $src"
    return
  fi

  snapshot_existing_repo_path "$dst"
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"

  if [ -e "$src" ] || [ -L "$src" ]; then
    cp -a "$src" "$dst"
  elif [ "$SUDO_AVAILABLE" -eq 1 ]; then
    sudo cp -a "$src" "$dst"
    sudo chown -R "$(id -u):$(id -g)" "$dst"
  else
    warn "Sem permissao para snapshot root: $src"
    return
  fi

  log "Snapshot root: $src -> $dst"
}

capture_swaync() {
  local src=''
  local dst="$DOTFILES_DIR/.config/swaync"

  if [ -d "$HOME/.config/swaync" ]; then
    src="$HOME/.config/swaync"
  elif [ -d "$HOME/.config/swaync_old" ]; then
    src="$HOME/.config/swaync_old"
  fi

  if [ -z "$src" ]; then
    warn 'Nenhuma config do swaync encontrada.'
    return
  fi

  snapshot_existing_repo_path "$dst"
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  log "Snapshot swaync: $src -> $dst"
}

write_inventory() {
  mkdir -p "$INVENTORY_DIR"

  pacman -Qqe | sort > "$INVENTORY_DIR/pacman-explicit.txt"
  pacman -Qqm | sort > "$INVENTORY_DIR/pacman-foreign.txt"
  find /etc/systemd/system -maxdepth 3 -type l | sort > "$INVENTORY_DIR/systemd-enabled-links.txt"
  find "$HOME/.config" -maxdepth 1 -mindepth 1 -type d -printf '.config/%f\n' | sort > "$INVENTORY_DIR/home-config-dirs.txt"

  if command -v lscpu >/dev/null 2>&1; then
    lscpu > "$INVENTORY_DIR/lscpu.txt"
  fi

  if command -v lspci >/dev/null 2>&1; then
    lspci > "$INVENTORY_DIR/lspci.txt"
  fi

  if command -v code >/dev/null 2>&1; then
    code --list-extensions | sort > "$INVENTORY_DIR/vscode-extensions.txt" || true
  fi

  log "Inventario atualizado em: $INVENTORY_DIR"
}

capture_webapps() {
  local manifest="$MANIFEST_DIR/webapps.tsv"
  local nativefier_json
  local name
  local target_url
  local app_dir
  local icon_src
  local icon_dst

  : > "$manifest"
  rm -rf "$ASSETS_DIR"
  mkdir -p "$ASSETS_DIR"

  if ! command -v jq >/dev/null 2>&1; then
    warn 'jq nao encontrado. Pulando manifest de webapps.'
    return
  fi

  shopt -s nullglob
  for nativefier_json in "$HOME"/Apps/WebApps/*/resources/app/nativefier.json; do
    name="$(jq -r '.name // empty' "$nativefier_json")"
    target_url="$(jq -r '.targetUrl // empty' "$nativefier_json")"
    if [ -z "$name" ] || [ -z "$target_url" ]; then
      continue
    fi

    app_dir="$(cd "$(dirname "$nativefier_json")/../.." && pwd)"
    icon_src="$app_dir/icon.png"
    icon_dst="$ASSETS_DIR/${name}.png"

    if [ -f "$icon_src" ]; then
      cp -a "$icon_src" "$icon_dst"
      printf '%s\t%s\t%s\n' "$name" "$target_url" "assets/webapps/icons/${name}.png" >> "$manifest"
    else
      warn "Icone nao encontrado para webapp: $name"
    fi
  done
  shopt -u nullglob

  log "Manifest de webapps atualizado em: $manifest"
}

prepare_root_access() {
  if command -v sudo >/dev/null 2>&1 && (sudo -n true 2>/dev/null || sudo -v 2>/dev/null); then
    SUDO_AVAILABLE=1
  fi
}

main() {
  ensure_dirs
  prepare_root_access

  local rel
  for rel in "${HOME_PATHS[@]}"; do
    copy_home_path "$rel"
  done

  capture_swaync

  local root_path
  for root_path in "${ROOT_PATHS[@]}"; do
    copy_root_path "$root_path"
  done

  capture_webapps
  write_inventory

  log "Snapshot salvo em: $STAMP_DIR"
  log "Dotfiles atualizados em: $DOTFILES_DIR"
}

main "$@"
