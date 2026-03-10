extends Node

class_name UIManager

# --- REFERENCIAS (conéctalas desde Juego.tscn) ---
@export var texto_estado: Label
@export var texto_tiempo: Label
@export var texto_puntos: Label
@export var boton_reiniciar: Button
@export var grid_container: GridContainer  # para rotar el tablero

# Colores de jugadores
const COLOR_J1 := Color(0.2, 0.6, 1.0)   # Azul
const COLOR_J2 := Color(1.0, 0.8, 0.2)   # Naranja

# ── TURNO ──
func mostrar_turno(jugador: int) -> void:
	texto_estado.text = "Turno del Jugador %d" % jugador
	texto_estado.modulate = COLOR_J1 if jugador == 1 else COLOR_J2
	_rotar_tablero(jugador)

func _rotar_tablero(jugador: int) -> void:
	await get_tree().process_frame
	grid_container.pivot_offset = grid_container.size / 2.0
	var angulo_destino := 0.0 if jugador == 1 else PI
	var tween := grid_container.create_tween()
	tween.tween_property(grid_container, "rotation", angulo_destino, 0.5)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)

# ── MENSAJES DE ESTADO ──
func mostrar_par_encontrado(jugador: int) -> void:
	texto_estado.text = "¡PUNTO para J%d!" % jugador
	texto_estado.modulate = COLOR_J1 if jugador == 1 else COLOR_J2

func mostrar_fallo() -> void:
	texto_estado.text = "No coinciden..."
	texto_estado.modulate = Color.RED

func mostrar_tira_otra_vez() -> void:
	texto_estado.text = "¡Tira otra vez!"

# ── MARCADORES ──
func actualizar_puntos(puntos_j1: int, puntos_j2: int, turnos: int) -> void:
	texto_puntos.text = "J1: %d  |  J2: %d  (Turnos: %d)" % [puntos_j1, puntos_j2, turnos]

# ── TIEMPO ──
func actualizar_tiempo(segundos: float) -> void:
	var mins := int(segundos / 60)
	var segs := int(segundos) % 60
	texto_tiempo.text = "Tiempo: %02d:%02d" % [mins, segs]

# ── FIN DEL JUEGO ──
func mostrar_fin(puntos_j1: int, puntos_j2: int) -> void:
	texto_tiempo.modulate = Color.YELLOW
	if puntos_j1 > puntos_j2:
		texto_estado.text = "¡GANÓ EL JUGADOR 1!"
		texto_estado.modulate = COLOR_J1
	elif puntos_j2 > puntos_j1:
		texto_estado.text = "¡GANÓ EL JUGADOR 2!"
		texto_estado.modulate = COLOR_J2
	else:
		texto_estado.text = "¡EMPATE!"
		texto_estado.modulate = Color.WHITE
	boton_reiniciar.show()
