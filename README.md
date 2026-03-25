# Hyprland Setup (Julio)

Bootstrap do seu Arch + Hyprland com snapshot real do ambiente atual.

Este repositório agora cobre:
- sessão Hyprland completa
- shell e utilitários de terminal
- temas GTK/cursor/ícones
- SDDM + Plymouth
- stack `systemd-networkd` + `systemd-resolved`
- apps de desktop e dev tools
- webapps Nativefier (via manifest)
- inventário de pacotes, serviços e hardware

## Perfis do instalador

O `install.sh` suporta 3 perfis:

- `minimal`: base Hyprland + shell + tema + utilitários principais
- `desktop`: `minimal` + boot/login + apps de desktop
- `full`: `desktop` + dev tools + virtualização + webapps

Padrão:

```bash
HYPR_SETUP_PROFILE=full
HYPR_SETUP_NETWORK_STACK=networkd
HYPR_SETUP_GPU_STACK=auto
HYPR_SETUP_CPU_UCODE=auto
HYPR_SETUP_ENABLE_WEBAPPS=auto
HYPR_SETUP_INSTALL_VSCODE_EXTENSIONS=auto
HYPR_SETUP_ENABLE_BLUETOOTH=0
```

## O que o `install.sh` faz

- detecta Arch Linux
- instala dependências de bootstrap (`base-devel`, `git`, `curl`)
- instala `yay` automaticamente, se necessário
- instala pacotes oficiais e AUR conforme o perfil escolhido
- faz backup local do que já existir em `~/.local/state/hyprland-setup/backup-*`
- restaura dotfiles de `~`, `~/.config`, `~/.local`, `~/.icons`, `~/Imagens` e `/etc`
- normaliza paths hardcoded (`/home/julio`) para o `$HOME` atual
- aplica tema GTK/cursor/ícones via `gsettings`
- configura serviços de rede conforme a stack escolhida
- habilita `sddm`, `docker`, `libvirtd` quando o perfil exigir
- remove Java não-LTS e define a JVM LTS preferida
- regenera o initramfs com `mkinitcpio -P` quando o perfil inclui boot
- recria webapps via `nativefier` usando `manifests/webapps.tsv`
- reinstala extensões do VS Code usando `inventory/vscode-extensions.txt`

## Backups gerados pelo `backup.sh`

### Home / dotfiles

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/waybar-pills`
- `~/.config/wofi`
- `~/.config/kitty`
- `~/.config/swaync` ou `~/.config/swaync_old`
- `~/.config/wlogout`
- `~/.config/btop`
- `~/.config/cava`
- `~/.config/satty`
- `~/.config/gtk-3.0`
- `~/.config/gtk-4.0`
- `~/.config/xsettingsd`
- `~/.config/fastfetch`
- `~/.config/nvim`
- `~/.config/Code/User/settings.json`
- `~/.config/Code/User/keybindings.json`
- `~/.config/starship.toml`
- `~/.config/mimeapps.list`
- `~/.local/bin`
- `~/.local/share/applications`
- `~/.icons/Catppuccin-Mocha-new`
- `~/.zshrc`
- `~/.gtkrc-2.0`
- `~/Imagens/Wallpapers`

### Root / sistema

- `/etc/sddm.conf`
- `/etc/mkinitcpio.conf`
- `/etc/plymouth/plymouthd.conf`
- `/etc/systemd/network`
- `/etc/systemd/zram-generator.conf`

### Manifests e inventário

- `manifests/webapps.tsv`
- `assets/webapps/icons/*`
- `inventory/pacman-explicit.txt`
- `inventory/pacman-foreign.txt`
- `inventory/systemd-enabled-links.txt`
- `inventory/home-config-dirs.txt`
- `inventory/lscpu.txt`
- `inventory/lspci.txt`
- `inventory/vscode-extensions.txt`

## Pacotes cobertos por perfil

### `minimal`

- Hyprland: `hyprland hypridle hyprlock hyprpaper hyprpicker waybar wofi awww`
- Portais / clipboard / screenshot: `xdg-desktop-portal-hyprland xdg-desktop-portal-gtk wl-clipboard cliphist wtype grim slurp satty jq python-gobject libnotify`
- Shell / terminal: `kitty zsh zsh-autosuggestions zsh-syntax-highlighting fastfetch fzf starship`
- Tema / desktop: `gnome-keyring polkit-gnome qt6ct noto-fonts ttf-jetbrains-mono-nerd otf-font-awesome papirus-icon-theme nwg-look`
- Ferramentas locais: `mission-center pavucontrol nemo file-roller nemo-fileroller mousepad neovim mpv imv unzip btop cava seahorse`
- AUR: `catppuccin-cursors-mocha catppuccin-gtk-theme-mocha wlogout wofi-calc pinta`

### `desktop`

Tudo do `minimal`, mais:

- Boot/login: `sddm plymouth efibootmgr btrfs-progs zram-generator`
- AUR boot: `catppuccin-sddm-theme-mocha plymouth-theme-catppuccin-mocha-git`
- Apps: `discord filezilla`
- AUR apps: `zen-browser-bin telegram-desktop-bin onlyoffice-bin postman-bin rustdesk-bin zapzap`

### `full`

Tudo do `desktop`, mais:

- Dev: `nodejs npm maven jdk17/jre17 jdk21/jre21 jdk25/jre25`
- AUR dev: `visual-studio-code-bin gitflow-avh ngrok webstorm intellij-idea-ultimate-edition android-studio`
- VM / containers: `docker docker-compose qemu-full virt-manager virt-viewer dnsmasq vde2 openbsd-netcat libvirt`
- Webapps: `nativefier-fork`

## Uso

### 1) Atualizar snapshot antes de formatar

```bash
cd ~/hyprland-setup
./backup.sh
```

### 2) Instalar em sistema limpo

```bash
cd ~/hyprland-setup
./install.sh
```

Se quiser bootstrap remoto sem clonar o repositório manualmente antes, baixe só o `install.sh`. Ele clona o resto sozinho usando o repositório padrão deste projeto:

```bash
curl -fsSL https://raw.githubusercontent.com/juliocesarcoutinhodev/hyprland-setup/main/install.sh -o install.sh && bash install.sh
```

Na máquina atual deste snapshot, `./install.sh` sozinho já replica o setup principal porque os defaults do script estão alinhados com este host:

- `HYPR_SETUP_PROFILE=full`
- `HYPR_SETUP_NETWORK_STACK=networkd`
- `HYPR_SETUP_GPU_STACK=auto` detecta AMD corretamente neste hardware
- `HYPR_SETUP_CPU_UCODE=auto` detecta AMD corretamente neste hardware
- `HYPR_SETUP_ENABLE_BLUETOOTH=0`

### 3) Escolher perfil e stack de rede

```bash
HYPR_SETUP_PROFILE=desktop \
HYPR_SETUP_NETWORK_STACK=networkd \
./install.sh
```

### 4) Forçar stack de rede via NetworkManager

```bash
HYPR_SETUP_PROFILE=desktop \
HYPR_SETUP_NETWORK_STACK=networkmanager \
HYPR_SETUP_ENABLE_BLUETOOTH=1 \
./install.sh
```

### 5) Forçar GPU / microcode

```bash
HYPR_SETUP_GPU_STACK=amd \
HYPR_SETUP_CPU_UCODE=amd \
./install.sh
```

Valores aceitos:

- `HYPR_SETUP_PROFILE`: `minimal`, `desktop`, `full`
- `HYPR_SETUP_NETWORK_STACK`: `networkd`, `networkmanager`, `none`
- `HYPR_SETUP_GPU_STACK`: `auto`, `amd`, `none`
- `HYPR_SETUP_CPU_UCODE`: `auto`, `amd`, `intel`, `none`
- `HYPR_SETUP_ENABLE_WEBAPPS`: `auto`, `0`, `1`
- `HYPR_SETUP_INSTALL_VSCODE_EXTENSIONS`: `auto`, `0`, `1`
- `HYPR_SETUP_ENABLE_BLUETOOTH`: `0`, `1`

## Notas importantes

- Os webapps não são versionados como binários. O repositório guarda o manifest e os ícones, e o `install.sh` os recria via `nativefier`.
- O snapshot do Hypr foi ajustado para ficar portátil entre máquinas: monitor genérico e wallpaper com `awww`.
- O perfil padrão usa `systemd-networkd` porque esse é o stack real da máquina atual.
- Se o objetivo for formatar esta mesma máquina e voltar para o mesmo setup, `./install.sh` já é o caminho padrão esperado.
- `linux-zen`, `amd-ucode` e `vulkan-radeon` existem no inventário da máquina, mas a instalação do driver/microcode fica guiada por autodetecção (`auto`) ou override explícito.
- Se você publicar este repo, revise arquivos com dados pessoais antes do push.

## Estrutura do repositório

- `dotfiles/`: snapshot restaurável
- `manifests/`: manifests declarativos, como `webapps.tsv`
- `assets/`: recursos auxiliares, como ícones dos webapps
- `inventory/`: inventário do host atual
- `backups/`: snapshots do estado anterior do próprio repositório
