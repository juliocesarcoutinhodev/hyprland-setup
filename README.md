# Hyprland Setup (Julio)

Instalacao automatica do seu Hyprland do zero (pacotes + AUR + dotfiles + temas).

## O que o `install.sh` faz

- detecta Arch Linux
- instala dependencias de bootstrap (`base-devel`, `git`, `curl`)
- instala `yay` automaticamente (se nao existir)
- instala pacotes oficiais essenciais + dev
- instala pacotes AUR (tema, browser, VS Code)
- faz backup do que ja existe em `~/.local/state/hyprland-setup/backup-*`
- restaura seus dotfiles (`hypr`, `waybar`, `wofi`, `kitty`, `swaync`, icones e wallpaper)
- ajusta paths hardcoded (`/home/julio`) para o `$HOME` atual
- aplica tema GTK/cursor/icon via `gsettings`
- habilita `NetworkManager` e `bluetooth`
- define Java default (`java-25-openjdk`, fallback `java-21-openjdk`)

## Pacotes cobertos (resumo)

Base Hyprland:
- `hyprland hypridle hyprlock hyprpaper waybar wofi swaync wlogout swww`

Captura e clipboard:
- `wl-clipboard cliphist wtype grim slurp satty`

Audio e sistema:
- `pipewire wireplumber pavucontrol playerctl gnome-keyring polkit-gnome`

Apps e dev:
- `gnome-calculator kitty nemo mission-center`
- `nodejs npm` (inclui `npx`)
- `jdk21-openjdk jre21-openjdk`
- `jdk25-openjdk jre25-openjdk`
- AUR: `visual-studio-code-bin zen-browser-bin`

Tema/fontes:
- `catppuccin-cursors-mocha catppuccin-gtk-theme-mocha`
- `ttf-jetbrains-mono-nerd`

## Uso

### 1) Atualizar snapshot antes de formatar

```bash
cd ~/hyprland-setup
./backup.sh
```

### 2) Instalar apos sistema limpo (repositorio ja clonado)

```bash
cd ~/hyprland-setup
./install.sh
```

### 3) Executar via `curl` (sem clone previo)

Use a URL do seu repo no `HYPR_SETUP_REPO`:

```bash
curl -fsSL https://raw.githubusercontent.com/SEU-USUARIO/SEU-REPO/main/install.sh | HYPR_SETUP_REPO='https://github.com/SEU-USUARIO/SEU-REPO.git' bash
```

## Estrutura restaurada

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/wofi`
- `~/.config/kitty`
- `~/.config/swaync`
- `~/.icons/Catppuccin-Mocha-new`
- `~/Imagens/Wallpapers/*`

## Publicar no GitHub

```bash
cd ~/hyprland-setup
git init
git add .
git commit -m "feat: hyprland full bootstrap installer"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/SEU-REPO.git
git push -u origin main
```
