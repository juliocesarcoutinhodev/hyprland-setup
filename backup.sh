#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$BASE_DIR/dotfiles"
STAMP_DIR="$BASE_DIR/backups/snapshot-$(date +%Y%m%d-%H%M%S)"

log() {
  printf '[hyprland-backup] %s\n' "$*"
}

copy_with_snapshot() {
  local src="$1"
  local dst="$2"
  local rel_dst="${dst#$BASE_DIR/}"

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$STAMP_DIR/$(dirname "$rel_dst")"
    cp -a "$dst" "$STAMP_DIR/$rel_dst"
  fi

  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
}

main() {
  mkdir -p "$DOTFILES_DIR/.config" "$DOTFILES_DIR/Imagens/Wallpapers"

  copy_with_snapshot "$HOME/.config/hypr" "$DOTFILES_DIR/.config/hypr"
  copy_with_snapshot "$HOME/.config/waybar" "$DOTFILES_DIR/.config/waybar"
  copy_with_snapshot "$HOME/.config/wofi" "$DOTFILES_DIR/.config/wofi"
  copy_with_snapshot "$HOME/.config/kitty" "$DOTFILES_DIR/.config/kitty"

  if [ -d "$HOME/.config/swaync" ]; then
    copy_with_snapshot "$HOME/.config/swaync" "$DOTFILES_DIR/.config/swaync"
  elif [ -d "$HOME/.config/swaync_old" ]; then
    copy_with_snapshot "$HOME/.config/swaync_old" "$DOTFILES_DIR/.config/swaync"
  fi

  if [ -d "$HOME/.icons/Catppuccin-Mocha-new" ]; then
    copy_with_snapshot "$HOME/.icons/Catppuccin-Mocha-new" "$DOTFILES_DIR/.icons/Catppuccin-Mocha-new"
  fi

  if [ -f "$HOME/Imagens/Wallpapers/arch.png" ]; then
    copy_with_snapshot "$HOME/Imagens/Wallpapers/arch.png" "$DOTFILES_DIR/Imagens/Wallpapers/arch.png"
  fi

  log "Snapshot salvo em: $STAMP_DIR"
  log "Dotfiles atualizados em: $DOTFILES_DIR"
}

main "$@"
