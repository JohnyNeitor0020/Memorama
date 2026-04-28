extends Node

# Datos que viajan del menú al juego
var nombre_j1 := "Nombre"
var nombre_j2 := "Jugador 2"
var parejas := 8  # 8 = fácil, 12 = normal, 16 = difícil

# Variables de red multijugador
var is_host: bool = false
var peer_id: int = 1
var players: Array = []
