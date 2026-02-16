#!/usr/bin/env python3
import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
import sys
import json
import signal

# Lida com o fechamento do script de forma limpa
def signal_handler(sig, frame):
    sys.exit(0)

class PlayerManager:
    def __init__(self):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()
        
        # Conecta eventos de novos players ou players que fecharam
        self.manager.connect("name-appeared", self.init_player)
        self.manager.connect("player-vanished", self.update_output)
        
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        self.init_players()

    def init_players(self):
        for player in self.manager.props.player_names:
            self.init_player(None, player)

    def init_player(self, _, player_name):
        player = Playerctl.Player.new_from_name(player_name)
        player.connect("playback-status", self.update_output)
        player.connect("metadata", self.update_output)
        self.manager.manage_player(player)
        self.update_output(player)

    def update_output(self, player, _=None):
        players = self.manager.props.players
        
        # Se não houver nenhum aplicativo de mídia aberto, remove da Waybar
        if not players:
            sys.stdout.write("{}\n")
            sys.stdout.flush()
            return

        # Prioriza o player que está tocando (Playing)
        active_player = next((p for p in players if p.props.status == "Playing"), players[0])
        
        artist = active_player.get_artist()
        title = active_player.get_title()
        status = active_player.props.status
        
        # Define o ícone conforme o estado (Play ou Pause)
        icon = " " if status == "Playing" else " "
        
        # Lista de nomes de processos que não devem ser exibidos como "mídia"
        noms_genericos = ["Chromium", "Zen Browser", "Spotify", "zen-browser", "chromium", "spotify"]
        
        track_info = ""
        if artist and title:
            track_info = f"{icon}{artist} - {title}"
        elif title and title not in noms_genericos:
            track_info = f"{icon}{title}"
        else:
            # Se cair aqui (ex: aba vazia do navegador), o módulo some da barra
            sys.stdout.write("{}\n")
            sys.stdout.flush()
            return

        # Gera o JSON para a Waybar
        output = {
            "text": track_info,
            "class": status.lower(),
            "alt": active_player.props.player_name
        }
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

if __name__ == "__main__":
    manager = PlayerManager()
    try:
        manager.loop.run()
    except Exception:
        sys.exit(0)