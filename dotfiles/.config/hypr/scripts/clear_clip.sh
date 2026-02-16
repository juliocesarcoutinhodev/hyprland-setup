#!/bin/bash
# Para o monitoramento
pkill wl-paste
# Limpa o banco de dados do cliphist
cliphist wipe
# Remove o arquivo físico (tentando os dois caminhos comuns)
rm -f ~/.cache/cliphist/db
rm -f ~/.cache/cliphist/history
# Reinicia o monitoramento
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &
# Avisa que deu certo
notify-send "Cliphist" "Histórico totalmente limpo!"
