# binds
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# =========================
# ZSH BASE (Configurações do Shell)
# =========================
[[ -o interactive ]] || return

# Histórico
HISTFILE=~/.zsh_history
HISTSIZE=20000
SAVEHIST=20000
setopt inc_append_history share_history

# Autocomplete
autoload -Uz compinit
compinit

# =========================
# USER CONFIG (Seus Alias e Paths)
# =========================
export PATH="$HOME/.local/bin:$PATH"
alias sysup="~/.local/bin/sysup"


# Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/tools/bin"

# Android Emulator - Pixel 9 Pro (detached)
alias emulador='nohup emulator -avd Pixel_9_Pro -gpu host > /dev/null 2>&1 & disown'

# =========================
# alias set java
alias jdk17="sudo archlinux-java set java-17-openjdk"
alias jdk21="sudo archlinux-java set java-21-openjdk"
alias jdk25="sudo archlinux-java set java-25-openjdk"

alias jaspersoft="GTK_THEME=Adwaita:light /opt/jaspersoft/Jaspersoft & disown"

# =========================
# PLUGINS
# =========================
# Autosuggestions (Sugestões baseadas no histórico)
ZSH_AUTOSUGGEST_USE_ASYNC=false
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
# Mantendo o caminho que você definiu:
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax Highlighting (Colorir comandos)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# =========================
# USER CONFIG (Seus Alias e Paths)
# =========================
export PATH="$HOME/.local/bin:$PATH"
alias sysup="~/.local/bin/sysup"

source <(fzf --zsh)

eval "$(starship init zsh)"

fastfetch
echo ""

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
