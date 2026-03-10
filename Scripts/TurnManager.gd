extends Node

class_name TurnManager

signal turno_cambiado(jugador_activo: int)

var jugador_activo := 1

func iniciar() -> void:
	jugador_activo = 1

func cambiar_turno() -> void:
	jugador_activo = 2 if jugador_activo == 1 else 1
	emit_signal("turno_cambiado", jugador_activo)

func obtener_turno() -> int:
	return jugador_activo
