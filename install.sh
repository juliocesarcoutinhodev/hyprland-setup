#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null || pwd)"
BASE_DIR="$SCRIPT_DIR"
DOTFILES_DIR="$BASE_DIR/dotfiles"
MANIFEST_DIR="$BASE_DIR/manifests"
INVENTORY_DIR="$BASE_DIR/inventory"
BACKUP_DIR="$HOME/.local/state/hyprland-setup/backup-$(date +%Y%m%d-%H%M%S)"
TMP_REPO_DIR=""

PROFILE="${HYPR_SETUP_PROFILE:-full}"
NETWORK_STACK="${HYPR_SETUP_NETWORK_STACK:-networkd}"
GPU_STACK="${HYPR_SETUP_GPU_STACK:-auto}"
CPU_UCODE="${HYPR_SETUP_CPU_UCODE:-auto}"
ENABLE_BLUETOOTH="${HYPR_SETUP_ENABLE_BLUETOOTH:-0}"
ENABLE_WEBAPPS="${HYPR_SETUP_ENABLE_WEBAPPS:-auto}"
INSTALL_VSCODE_EXTENSIONS="${HYPR_SETUP_INSTALL_VSCODE_EXTENSIONS:-auto}"

PACMAN_BOOTSTRAP=(base-devel git curl)

PACMAN_CORE=(
  hyprland hypridle hyprlock hyprpaper hyprpicker xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  waybar wofi awww
  wl-clipboard cliphist wtype grim slurp satty jq python-gobject libnotify
  kitty nemo mission-center gnome-calculator pavucontrol
  pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber playerctl
  gnome-keyring polkit-gnome qt6ct noto-fonts ttf-jetbrains-mono-nerd otf-font-awesome
  zsh zsh-autosuggestions zsh-syntax-highlighting fastfetch fzf starship
  btop cava nwg-look papirus-icon-theme
  file-roller nemo-fileroller mousepad neovim unzip mpv imv seahorse
)

AUR_CORE=(
  catppuccin-cursors-mocha
  catppuccin-gtk-theme-mocha
  wlogout
  wofi-calc
  pinta
)

PACMAN_BOOT=(
  sddm plymouth efibootmgr btrfs-progs zram-generator
)

AUR_BOOT=(
  catppuccin-sddm-theme-mocha
  plymouth-theme-catppuccin-mocha-git
)

PACMAN_APPS=(
  discord filezilla
)

AUR_APPS=(
  zen-browser-bin
  telegram-desktop-bin
  onlyoffice-bin
  postman-bin
  rustdesk-bin
  zapzap
)

PACMAN_DEV=(
  nodejs npm maven
  jdk17-openjdk jre17-openjdk
  jdk21-openjdk jre21-openjdk
  jdk25-openjdk jre25-openjdk
)

AUR_DEV=(
  visual-studio-code-bin
  gitflow-avh
  ngrok
  webstorm
  intellij-idea-ultimate-edition
  android-studio
)

PACMAN_VM=(
  docker docker-compose
  qemu-full virt-manager virt-viewer dnsmasq vde2 openbsd-netcat libvirt
)

AUR_WEBAPPS=(
  nativefier-fork
)

PACMAN_NETWORKMANAGER=(
  networkmanager network-manager-applet
)

PACMAN_BLUETOOTH=(
  bluez bluez-utils blueman
)

PACMAN_CPU_AMD=(amd-ucode)
PACMAN_CPU_INTEL=(intel-ucode)
PACMAN_GPU_AMD=(vulkan-radeon)

HOME_CORE_PATHS=(
  .config/hypr
  .config/waybar
  .config/waybar-pills
  .config/wofi
  .config/kitty
  .config/swaync
  .config/wlogout
  .config/btop
  .config/cava
  .config/satty
  .config/gtk-3.0
  .config/gtk-4.0
  .config/xsettingsd
  .config/fastfetch
  .config/starship.toml
  .config/mimeapps.list
  .icons/Catppuccin-Mocha-new
  .local/bin
  .zshrc
  .gtkrc-2.0
  Imagens/Wallpapers
)

HOME_DEV_PATHS=(
  .config/nvim
  .config/Code/User/settings.json
  .config/Code/User/keybindings.json
)

HOME_WEBAPP_PATHS=(
  .local/share/applications
)

ROOT_BOOT_PATHS=(
  etc/sddm.conf
  etc/mkinitcpio.conf
  etc/plymouth/plymouthd.conf
  etc/systemd/zram-generator.conf
)

ROOT_NETWORKD_PATHS=(
  etc/systemd/network
)

PACMAN_SELECTED=()
AUR_SELECTED=()
HOME_SELECTED=()
ROOT_SELECTED=()
ENABLE_BOOT=0
ENABLE_APPS=0
ENABLE_DEV=0
ENABLE_VM=0

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

is_truthy() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

array_contains() {
  local -n haystack="$1"
  local needle="$2"
  local item
  for item in "${haystack[@]:-}"; do
    if [ "$item" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

append_unique() {
  local -n target="$1"
  shift
  local item
  for item in "$@"; do
    if [ -n "$item" ] && ! array_contains target "$item"; then
      target+=("$item")
    fi
  done
}

ensure_arch() {
  if ! command -v pacman >/dev/null 2>&1; then
    log 'Este script foi feito para Arch Linux (pacman).'
    exit 1
  fi
}

ensure_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    log 'sudo nao encontrado. Instale sudo e rode novamente.'
    exit 1
  fi
  sudo -v
}

validate_profile() {
  case "$PROFILE" in
    minimal)
      ;;
    desktop)
      ENABLE_BOOT=1
      ENABLE_APPS=1
      ;;
    full)
      ENABLE_BOOT=1
      ENABLE_APPS=1
      ENABLE_DEV=1
      ENABLE_VM=1
      ;;
    *)
      log "Perfil invalido: $PROFILE"
      log 'Use: minimal, desktop ou full'
      exit 1
      ;;
  esac

  case "$NETWORK_STACK" in
    networkd|networkmanager|none)
      ;;
    *)
      log "HYPR_SETUP_NETWORK_STACK invalido: $NETWORK_STACK"
      log 'Use: networkd, networkmanager ou none'
      exit 1
      ;;
  esac
}

resolve_webapp_toggle() {
  if [ "$ENABLE_WEBAPPS" = 'auto' ]; then
    if [ "$PROFILE" = 'minimal' ]; then
      ENABLE_WEBAPPS=0
    else
      ENABLE_WEBAPPS=1
    fi
  fi

  if [ "$INSTALL_VSCODE_EXTENSIONS" = 'auto' ]; then
    if [ "$ENABLE_DEV" -eq 1 ]; then
      INSTALL_VSCODE_EXTENSIONS=1
    else
      INSTALL_VSCODE_EXTENSIONS=0
    fi
  fi
}

resolve_cpu_vendor() {
  case "$CPU_UCODE" in
    amd|intel|none)
      printf '%s\n' "$CPU_UCODE"
      return
      ;;
    auto)
      if command -v lscpu >/dev/null 2>&1; then
        case "$(lscpu | awk -F: '/Vendor ID/ {gsub(/^ +/, "", $2); print $2; exit}')" in
          AuthenticAMD)
            printf 'amd\n'
            return
            ;;
          GenuineIntel)
            printf 'intel\n'
            return
            ;;
        esac
      fi
      printf 'none\n'
      return
      ;;
    *)
      warn "HYPR_SETUP_CPU_UCODE invalido: $CPU_UCODE. Usando none."
      printf 'none\n'
      return
      ;;
  esac
}

resolve_gpu_vendor() {
  case "$GPU_STACK" in
    amd|none)
      printf '%s\n' "$GPU_STACK"
      return
      ;;
    auto)
      if command -v lspci >/dev/null 2>&1 && lspci | grep -Eqi 'VGA|3D|Display'; then
        if lspci | grep -Ei 'VGA|3D|Display' | grep -Eqi 'AMD|ATI'; then
          printf 'amd\n'
          return
        fi
      fi
      printf 'none\n'
      return
      ;;
    *)
      warn "HYPR_SETUP_GPU_STACK invalido: $GPU_STACK. Usando none."
      printf 'none\n'
      return
      ;;
  esac
}

collect_paths_and_packages() {
  local cpu_vendor
  local gpu_vendor

  append_unique PACMAN_SELECTED "${PACMAN_CORE[@]}"
  append_unique AUR_SELECTED "${AUR_CORE[@]}"
  append_unique HOME_SELECTED "${HOME_CORE_PATHS[@]}"

  if [ "$ENABLE_BOOT" -eq 1 ]; then
    append_unique PACMAN_SELECTED "${PACMAN_BOOT[@]}"
    append_unique AUR_SELECTED "${AUR_BOOT[@]}"
    append_unique ROOT_SELECTED "${ROOT_BOOT_PATHS[@]}"

    cpu_vendor="$(resolve_cpu_vendor)"
    case "$cpu_vendor" in
      amd)
        append_unique PACMAN_SELECTED "${PACMAN_CPU_AMD[@]}"
        ;;
      intel)
        append_unique PACMAN_SELECTED "${PACMAN_CPU_INTEL[@]}"
        ;;
    esac
  fi

  if [ "$ENABLE_APPS" -eq 1 ]; then
    append_unique PACMAN_SELECTED "${PACMAN_APPS[@]}"
    append_unique AUR_SELECTED "${AUR_APPS[@]}"
  fi

  if [ "$ENABLE_DEV" -eq 1 ]; then
    append_unique PACMAN_SELECTED "${PACMAN_DEV[@]}"
    append_unique AUR_SELECTED "${AUR_DEV[@]}"
    append_unique HOME_SELECTED "${HOME_DEV_PATHS[@]}"
  fi

  if [ "$ENABLE_VM" -eq 1 ]; then
    append_unique PACMAN_SELECTED "${PACMAN_VM[@]}"
  fi

  if is_truthy "$ENABLE_WEBAPPS"; then
    append_unique AUR_SELECTED "${AUR_WEBAPPS[@]}"
    append_unique HOME_SELECTED "${HOME_WEBAPP_PATHS[@]}"
  fi

  case "$NETWORK_STACK" in
    networkd)
      append_unique ROOT_SELECTED "${ROOT_NETWORKD_PATHS[@]}"
      ;;
    networkmanager)
      append_unique PACMAN_SELECTED "${PACMAN_NETWORKMANAGER[@]}"
      ;;
  esac

  if is_truthy "$ENABLE_BLUETOOTH"; then
    append_unique PACMAN_SELECTED "${PACMAN_BLUETOOTH[@]}"
  fi

  gpu_vendor="$(resolve_gpu_vendor)"
  case "$gpu_vendor" in
    amd)
      append_unique PACMAN_SELECTED "${PACMAN_GPU_AMD[@]}"
      ;;
  esac
}

pacman_install_missing() {
  local -a desired=("$@")
  local -a available=()
  local -a missing=()
  local pkg

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
    log 'Pacotes oficiais ja estao instalados.'
  fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  log 'yay nao encontrado. Instalando yay automaticamente...'
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
  local pkg

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
    log 'Pacotes AUR ja estao instalados.'
  fi
}

ensure_dotfiles_available() {
  if [ -d "$DOTFILES_DIR/.config/hypr" ]; then
    return
  fi

  local repo_url="${HYPR_SETUP_REPO:-}"
  if [ -z "$repo_url" ]; then
    log 'Dotfiles nao encontrados ao lado do script.'
    log 'Defina HYPR_SETUP_REPO para clonar automaticamente o repositorio com os dotfiles.'
    log "Exemplo: HYPR_SETUP_REPO='https://github.com/seu-usuario/hyprland-setup.git' bash install.sh"
    exit 1
  fi

  log "Clonando repositorio de dotfiles: $repo_url"
  pacman_install_missing "${PACMAN_BOOTSTRAP[@]}"

  TMP_REPO_DIR="$(mktemp -d /tmp/hyprland-setup-XXXXXX)"
  git clone --depth 1 "$repo_url" "$TMP_REPO_DIR"

  BASE_DIR="$TMP_REPO_DIR"
  DOTFILES_DIR="$BASE_DIR/dotfiles"
  MANIFEST_DIR="$BASE_DIR/manifests"
  INVENTORY_DIR="$BASE_DIR/inventory"

  if [ ! -d "$DOTFILES_DIR/.config/hypr" ]; then
    log "Repositorio clonado, mas estrutura dotfiles invalida: $DOTFILES_DIR"
    exit 1
  fi
}

backup_path_if_exists() {
  local target="$1"
  local use_sudo="${2:-0}"
  local rel
  local dst

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return
  fi

  if [[ "$target" == "$HOME"/* ]]; then
    rel="${target#$HOME/}"
  else
    rel="${target#/}"
  fi
  dst="$BACKUP_DIR/$rel"

  if is_truthy "$use_sudo"; then
    sudo mkdir -p "$(dirname "$dst")"
    sudo mv "$target" "$dst"
    sudo chown -R "$(id -u):$(id -g)" "$BACKUP_DIR" 2>/dev/null || true
  else
    mkdir -p "$(dirname "$dst")"
    mv "$target" "$dst"
  fi

  log "Backup: $target -> $dst"
}

restore_path() {
  local src="$1"
  local dst="$2"
  local use_sudo="${3:-0}"

  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    warn "Origem nao encontrada, pulando restore: $src"
    return
  fi

  backup_path_if_exists "$dst" "$use_sudo"

  if is_truthy "$use_sudo"; then
    sudo mkdir -p "$(dirname "$dst")"
    sudo cp -a "$src" "$dst"
  else
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
  fi

  log "Restaurado: $dst"
}

restore_selected_paths() {
  local rel

  log "Criando backup local em: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"

  for rel in "${HOME_SELECTED[@]}"; do
    restore_path "$DOTFILES_DIR/$rel" "$HOME/$rel"
  done

  for rel in "${ROOT_SELECTED[@]}"; do
    restore_path "$DOTFILES_DIR/$rel" "/$rel" 1
  done

  mkdir -p "$HOME/Imagens/Screenshots"
  chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true
  chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
}

normalize_paths() {
  local candidate
  local -a roots=(
    "$HOME/.config"
    "$HOME/.local/bin"
    "$HOME/.local/share/applications"
    "$HOME/.zshrc"
    "$HOME/.gtkrc-2.0"
  )

  while IFS= read -r -d '' candidate; do
    if grep -Iq . "$candidate" 2>/dev/null && grep -q '/home/julio/' "$candidate" 2>/dev/null; then
      sed -i "s|/home/julio/|$HOME/|g" "$candidate"
    fi
  done < <(find "${roots[@]}" -type f -print0 2>/dev/null)
}

apply_theme_defaults() {
  if command -v gsettings >/dev/null 2>&1; then
    log 'Aplicando tema GTK/cursor/icon via gsettings'
    gsettings set org.gnome.desktop.interface cursor-theme 'catppuccin-mocha-sky-cursors' || true
    gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-sky-standard+default' || true
    gsettings set org.gnome.desktop.interface icon-theme 'Catppuccin-Mocha-new' || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  fi
}

configure_network_services() {
  case "$NETWORK_STACK" in
    networkd)
      sudo systemctl disable --now NetworkManager 2>/dev/null || true
      sudo systemctl enable --now systemd-networkd systemd-resolved || true
      sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf || true
      ;;
    networkmanager)
      sudo systemctl disable --now systemd-networkd systemd-resolved 2>/dev/null || true
      sudo systemctl enable --now NetworkManager || true
      ;;
    none)
      ;;
  esac
}

configure_services() {
  if [ "$ENABLE_BOOT" -eq 1 ] && systemctl list-unit-files | grep -q '^sddm\.service'; then
    sudo systemctl enable --now sddm || true
  fi

  configure_network_services

  if is_truthy "$ENABLE_BLUETOOTH" && systemctl list-unit-files | grep -q '^bluetooth\.service'; then
    sudo systemctl enable --now bluetooth || true
  fi

  if [ "$ENABLE_VM" -eq 1 ] && systemctl list-unit-files | grep -q '^docker\.service'; then
    sudo systemctl enable --now docker || true
  fi

  if [ "$ENABLE_VM" -eq 1 ] && systemctl list-unit-files | grep -q '^libvirtd\.service'; then
    sudo systemctl enable --now libvirtd || true
  fi
}

configure_java_lts() {
  local -a non_lts_java=(
    jdk-openjdk
    jre-openjdk
    jre-openjdk-headless
  )
  local -a installed_non_lts=()
  local pkg

  for pkg in "${non_lts_java[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
      installed_non_lts+=("$pkg")
    fi
  done

  if ((${#installed_non_lts[@]} > 0)); then
    log "Removendo Java nao-LTS: ${installed_non_lts[*]}"
    sudo pacman -Rns --noconfirm "${installed_non_lts[@]}" || warn 'Falha ao remover Java nao-LTS. Verifique dependencias.'
  fi

  if command -v archlinux-java >/dev/null 2>&1; then
    if archlinux-java status | grep -q 'java-25-openjdk'; then
      sudo archlinux-java set java-25-openjdk || true
    elif archlinux-java status | grep -q 'java-21-openjdk'; then
      sudo archlinux-java set java-21-openjdk || true
    elif archlinux-java status | grep -q 'java-17-openjdk'; then
      sudo archlinux-java set java-17-openjdk || true
    fi
  fi
}

rebuild_initramfs() {
  if [ "$ENABLE_BOOT" -eq 1 ] && command -v mkinitcpio >/dev/null 2>&1 && [ -f /etc/mkinitcpio.conf ]; then
    log 'Regenerando initramfs com mkinitcpio -P'
    sudo mkinitcpio -P || warn 'Falha ao regenerar initramfs.'
  fi
}

install_vscode_extensions() {
  local ext_file="$INVENTORY_DIR/vscode-extensions.txt"
  local ext

  if ! is_truthy "$INSTALL_VSCODE_EXTENSIONS"; then
    return
  fi
  if [ ! -f "$ext_file" ]; then
    return
  fi
  if ! command -v code >/dev/null 2>&1; then
    warn 'VS Code nao encontrado no PATH. Pulando extensoes.'
    return
  fi

  log 'Instalando extensoes do VS Code'
  while IFS= read -r ext; do
    [ -n "$ext" ] || continue
    code --install-extension "$ext" --force >/dev/null 2>&1 || warn "Falha ao instalar extensao: $ext"
  done < "$ext_file"
}

write_webapp_desktop() {
  local name="$1"
  local exec_path="$2"
  local icon_path="$3"
  local desktop_id

  desktop_id="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
  cat > "$HOME/.local/share/applications/${desktop_id}.desktop" <<DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=$name
Exec=$exec_path %U
Icon=$icon_path
Terminal=false
Categories=Network;WebBrowser;
StartupWMClass=$name
DESKTOP
}

install_webapps() {
  local manifest="$MANIFEST_DIR/webapps.tsv"
  local name
  local url
  local icon_rel
  local icon_src
  local app_dir

  if ! is_truthy "$ENABLE_WEBAPPS"; then
    return
  fi
  if [ ! -f "$manifest" ]; then
    return
  fi
  if ! command -v nativefier >/dev/null 2>&1; then
    warn 'nativefier nao encontrado. Pulando instalacao dos webapps.'
    return
  fi

  mkdir -p "$HOME/Apps/WebApps" "$HOME/.local/share/applications"

  while IFS=$'\t' read -r name url icon_rel; do
    [ -n "$name" ] || continue
    [ -n "$url" ] || continue

    icon_src="$BASE_DIR/$icon_rel"
    if [ ! -f "$icon_src" ]; then
      warn "Icone nao encontrado para webapp $name: $icon_src"
      continue
    fi

    app_dir="$HOME/Apps/WebApps/${name}-linux-x64"
    if [ -d "$app_dir" ]; then
      backup_path_if_exists "$app_dir"
    fi

    log "Gerando webapp: $name"
    (
      cd "$HOME/Apps/WebApps"
      nativefier \
        --name "$name" \
        --icon "$icon_src" \
        --single-instance \
        --enable-features='UseOzonePlatform' \
        --ozone-platform='wayland' \
        "$url"
    ) || warn "Falha ao gerar webapp: $name"

    if [ -x "$app_dir/$name" ]; then
      write_webapp_desktop "$name" "$app_dir/$name" "$app_dir/icon.png"
    fi
  done < "$manifest"
}

post_checks() {
  log 'Resumo de comandos criticos:'
  local -a cmds=(
    hyprland hyprctl hypridle hyprlock waybar wofi swaync wlogout
    awww awww-daemon wl-paste cliphist wl-copy wtype grim slurp satty jq
    wpctl pavucontrol kitty missioncenter fastfetch zsh
  )
  local c

  if [ "$ENABLE_APPS" -eq 1 ]; then
    append_unique cmds zen-browser rustdesk discord telegram-desktop
  fi

  if [ "$ENABLE_DEV" -eq 1 ]; then
    append_unique cmds code java javac node npm npx nvim
  fi

  if [ "$ENABLE_VM" -eq 1 ]; then
    append_unique cmds docker virt-manager
  fi

  if is_truthy "$ENABLE_WEBAPPS"; then
    append_unique cmds nativefier
  fi

  for c in "${cmds[@]}"; do
    if command -v "$c" >/dev/null 2>&1; then
      printf '  [ok] %s\n' "$c"
    else
      printf '  [!!] faltando: %s\n' "$c"
    fi
  done
}

main() {
  validate_profile
  resolve_webapp_toggle
  collect_paths_and_packages

  log "Perfil: $PROFILE"
  log "Pilha de rede: $NETWORK_STACK"
  log "GPU stack: $(resolve_gpu_vendor)"
  log "CPU ucode: $(resolve_cpu_vendor)"

  ensure_arch
  ensure_sudo

  pacman_install_missing "${PACMAN_BOOTSTRAP[@]}"
  ensure_yay
  ensure_dotfiles_available

  pacman_install_missing "${PACMAN_SELECTED[@]}"
  aur_install_missing "${AUR_SELECTED[@]}"

  restore_selected_paths
  normalize_paths
  apply_theme_defaults
  configure_services
  configure_java_lts
  rebuild_initramfs
  install_webapps
  install_vscode_extensions
  post_checks

  log 'Concluido. Reinicie ou faca logout/login para aplicar tudo no Hyprland.'
}

main "$@"
