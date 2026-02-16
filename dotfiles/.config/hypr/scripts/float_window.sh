#!/bin/bash

# Pega o status da janela atual (Se está flutuando ou não)
STATUS=$(hyprctl activewindow -j | jq -r '.floating')

if [ "$STATUS" == "false" ]; then
    # Se NÃO estiver flutuando (está presa):
    hyprctl dispatch togglefloating      # 1. Solta a janela
    hyprctl dispatch resizeactive exact 1000 600  # 2. Define tamanho (Largura x Altura)
    hyprctl dispatch centerwindow        # 3. Centraliza
else
    # Se JÁ estiver flutuando:
    hyprctl dispatch togglefloating      # Apenas prende de volta
fi
