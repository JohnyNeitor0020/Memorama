extends Node2D

# --- CONFIGURACIÓN ---
@export var escena_carta: PackedScene
@export var texturas_cartas: Array[Texture2D]

# --- REFERENCIAS A MANAGERS ---
@onready var ui_manager: UIManager = $UIManager
@onready var turn_manager: TurnManager = $TurnManager

# --- REFERENCIAS DE ESCENA ---
@onready var grid_container: GridContainer = $CanvasLayer/GridContainer
@onready var audio_voltear: AudioStreamPlayer = $AudioVoltear
@onready var audio_par: AudioStreamPlayer = $AudioPar

# --- ESTADO DE JUEGO ---
var cartas_en_mesa: Array[Carta] = []
var cartas_seleccionadas: Array[Carta] = []

var puntos_j1 := 0
var puntos_j2 := 0
var parejas_encontradas := 0
var parejas_totales := 0
var tiempo_juego := 0.0
var juego_terminado := false
var contador_turnos := 0

func _ready() -> void:
	# 1. Leer dificultad desde el menú
	parejas_totales = GameData.parejas

	# 2. Evitar que se salgan de la mesa (Ajustar columnas y escala)
	grid_container.pivot_offset = grid_container.size / 2.0
	
	if parejas_totales <= 8:
		grid_container.columns = 4  # 4x4 (16 cartas)
		grid_container.scale = Vector2(0.6, 0.6) # Tamaño normal
	elif parejas_totales <= 12:
		grid_container.columns = 6  # 6x4 (24 cartas)
		grid_container.scale = Vector2(0.6, 0.6) # Un poco más chicas
	else:
		grid_container.columns = 8  # 8x4 (32 cartas)
		grid_container.scale = Vector2(0.65, 0.65) # Más chicas para que quepan

	# 3. Iniciar juego
	turn_manager.iniciar()
	turn_manager.turno_cambiado.connect(_on_turno_cambiado)
	
	# Asegurar que el botón de reiniciar empiece oculto
	ui_manager.boton_reiniciar.hide()
	
	ui_manager.actualizar_puntos(0, 0, 0)
	ui_manager.mostrar_turno(turn_manager.obtener_turno())
	ui_manager.actualizar_nombres(GameData.nombre_j1, GameData.nombre_j2)
	generar_tablero()

func _process(delta: float) -> void:
	if juego_terminado:
		return
	tiempo_juego += delta
	ui_manager.actualizar_tiempo(tiempo_juego)

# ── TABLERO ──
func generar_tablero() -> void:
	var num_texturas = texturas_cartas.size()
	
	# CORRECCIÓN DE PARES: Si pides 16 pares pero solo hay 13 fotos,
	# el juego se limitará a 13 pares para no crear "falsos positivos" y romper la lógica.
	if parejas_totales > num_texturas:
		parejas_totales = num_texturas

	var ids: Array[int] = []
	for i in range(parejas_totales):
		ids.append(i)
		ids.append(i)
	ids.shuffle()

	for id in ids:
		var nueva_carta: Carta = escena_carta.instantiate()
		grid_container.add_child(nueva_carta)
		# Le asignamos directamente la textura (sin la fórmula que rompía el juego)
		nueva_carta.configurar(id, texturas_cartas[id])
		nueva_carta.carta_seleccionada.connect(_on_carta_tocada)
		cartas_en_mesa.append(nueva_carta)

# ── LÓGICA DE CARTAS ──
func _on_carta_tocada(carta: Carta) -> void:
	if cartas_seleccionadas.size() >= 2 or juego_terminado:
		return
	audio_voltear.play()
	carta.voltear()
	cartas_seleccionadas.append(carta)
	if cartas_seleccionadas.size() == 2:
		contador_turnos += 1
		_verificar_par()

func _verificar_par() -> void:
	var c1 := cartas_seleccionadas[0]
	var c2 := cartas_seleccionadas[1]
	var jugador_actual := turn_manager.obtener_turno()

	if c1.id_pareja == c2.id_pareja:
		_on_par_encontrado(c1, c2, jugador_actual)
	else:
		_on_par_fallido(c1, c2)

func _on_par_encontrado(c1: Carta, c2: Carta, jugador: int) -> void:
	ui_manager.mostrar_par_encontrado(jugador)

	if jugador == 1:
		puntos_j1 += 1
	else:
		puntos_j2 += 1

	parejas_encontradas += 1
	ui_manager.actualizar_puntos(puntos_j1, puntos_j2, contador_turnos)

	await get_tree().create_timer(0.4).timeout
	audio_par.play()
	c1.resaltar_par()
	c2.resaltar_par()
	cartas_seleccionadas.clear()

	if parejas_encontradas == parejas_totales:
		_fin_del_juego()
	else:
		ui_manager.mostrar_tira_otra_vez()

func _on_par_fallido(c1: Carta, c2: Carta) -> void:
	ui_manager.mostrar_fallo()
	await get_tree().create_timer(1.0).timeout
	c1.ocultar_carta()
	c2.ocultar_carta()
	cartas_seleccionadas.clear()
	turn_manager.cambiar_turno()

# ── TURNO ──
func _on_turno_cambiado(jugador: int) -> void:
	ui_manager.mostrar_turno(jugador)
	ui_manager.actualizar_puntos(puntos_j1, puntos_j2, contador_turnos)

# ── FIN ──
func _fin_del_juego() -> void:
	juego_terminado = true
	ui_manager.mostrar_fin(puntos_j1, puntos_j2)

func _on_boton_reiniciar_pressed() -> void:
	get_tree().reload_current_scene()
