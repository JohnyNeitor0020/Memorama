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
@onready var panel_ajustes: Panel = $CanvasLayer/PanelAjustes
@onready var slider_volumen: HSlider = $CanvasLayer/PanelAjustes/HSlider

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
var rematch_votos := 0
var mazo_servidor: Array = [] # Guardar mazo para nuevos sincronismos

func _ready() -> void:
	# 1. Leer dificultad desde el menú
	parejas_totales = GameData.parejas

	# 2. Conectar ajustes de sonido
	slider_volumen.value_changed.connect(_on_volumen_cambiado)
	slider_volumen.value = 0.5
	panel_ajustes.hide() # Asegurarnos de que empiece oculto
	
	if parejas_totales <= 8:
		grid_container.columns = 4  # 4x4 (16 cartas)
	elif parejas_totales <= 12:
		grid_container.columns = 6  # 6x4 (24 cartas)
	else:
		grid_container.columns = 8  # 8x4 (32 cartas)

	# 3. Iniciar juego (La lógica del turno la maneja el Host)
	turn_manager.turno_cambiado.connect(_on_turno_cambiado)
	
	# Asegurar que los botones de fin de juego empiecen ocultos
	ui_manager.boton_reiniciar.hide()
	ui_manager.boton_salir.show() # El botón de Menú (Salir) debe estar siempre visible
	
	ui_manager.actualizar_puntos(0, 0, 0)
	ui_manager.actualizar_nombres(GameData.nombre_j1, GameData.nombre_j2)
	
	if GameData.my_role == GameData.Role.SERVER:
		turn_manager.iniciar()
		generar_tablero()
		# El servidor no tiene UI, pero sí controla el flujo
		ui_manager.mostrar_turno(turn_manager.obtener_turno())
	else:
		# Si soy cliente, le pido al servidor los datos iniciales (por si me los perdí al cargar)
		rpc_id(1, "request_initial_sync")
	
	# 4. Señales de red para abandono
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(delta: float) -> void:
	if juego_terminado:
		return
	tiempo_juego += delta
	ui_manager.actualizar_tiempo(tiempo_juego)

# ── TABLERO ──
func generar_tablero() -> void:
	if GameData.my_role != GameData.Role.SERVER:
		return # El cliente espera el tablero del servidor
		
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
	mazo_servidor = ids

	# El Host envía el arreglo a los clientes y a sí mismo
	rpc("sync_board", mazo_servidor)
	rpc("sync_turn", turn_manager.obtener_turno(), 0, 0, 0)

@rpc("any_peer", "call_remote", "reliable")
func request_initial_sync() -> void:
	if GameData.my_role == GameData.Role.SERVER:
		var peer_id = multiplayer.get_remote_sender_id()
		print("Sincronizando cliente ", peer_id)
		# Enviamos específicamente al que lo pidió
		rpc_id(peer_id, "sync_board", mazo_servidor)
		rpc_id(peer_id, "sync_turn", turn_manager.obtener_turno(), puntos_j1, puntos_j2, contador_turnos)

@rpc("authority", "call_local", "reliable")
func sync_board(server_deck: Array) -> void:
	# Limpiamos el tablero por si es una re-sincronización y evitar duplicados
	for carta in cartas_en_mesa:
		if is_instance_valid(carta):
			carta.queue_free()
	cartas_en_mesa.clear()

	for id in server_deck:
		var nueva_carta: Carta = escena_carta.instantiate()
		grid_container.add_child(nueva_carta)
		# Le asignamos directamente la textura
		nueva_carta.configurar(id, texturas_cartas[id])
		nueva_carta.carta_seleccionada.connect(_on_carta_tocada)
		cartas_en_mesa.append(nueva_carta)
		
	# 1. Esperamos DOS fotogramas para asegurar que Godot registró todos los nodos nuevos
	await get_tree().process_frame
	await get_tree().process_frame 

	# 2. Obligamos al contenedor a recalcular su tamaño real con las cartas dentro
	grid_container.reset_size()

	# 3. Ahora sí, calculamos el centro perfecto con el tamaño real actualizado
	grid_container.pivot_offset = grid_container.size / 2.0

	# 4. Aplicamos la escala correspondiente
	if parejas_totales <= 8:
		grid_container.scale = Vector2(0.6, 0.6)
	elif parejas_totales <= 12:
		grid_container.scale = Vector2(0.6, 0.6)
	else:
		grid_container.scale = Vector2(0.65, 0.65)
	
	# 5. Centrado manual absoluto (Garantiza que se vea igual en Host y Cliente)
	var screen_size = Vector2(1280, 720) 
	var scaled_size = grid_container.size * grid_container.scale
	grid_container.global_position = (screen_size / 2.0) - (scaled_size / 2.0)

# ── LÓGICA DE CARTAS ──
func _on_carta_tocada(carta: Carta) -> void:
	if juego_terminado:
		return
	var index = cartas_en_mesa.find(carta)
	if index != -1:
		# Pide permiso al host para voltear
		rpc_id(1, "request_flip_card", index, multiplayer.get_unique_id())

@rpc("any_peer", "call_local", "reliable")
func request_flip_card(card_index: int, requester_id: int) -> void:
	if GameData.my_role != GameData.Role.SERVER:
		return
		
	# Mapeamos: P1 es Turno 1, P2 es Turno 2
	var turno_esperado = 1 if requester_id == GameData.p1_peer_id else 2
	if turn_manager.obtener_turno() != turno_esperado:
		return
		
	if cartas_seleccionadas.size() >= 2:
		return
		
	var carta = cartas_en_mesa[card_index]
	if cartas_seleccionadas.has(carta):
		return
		
	# Ejecutar volteo visual en todos los clientes
	rpc("execute_flip_card", card_index)
	
	cartas_seleccionadas.append(carta)
	if cartas_seleccionadas.size() == 2:
		contador_turnos += 1
		_verificar_par()

@rpc("authority", "call_local", "reliable")
func execute_flip_card(card_index: int) -> void:
	audio_voltear.play()
	cartas_en_mesa[card_index].voltear()

func _verificar_par() -> void:
	var c1 := cartas_seleccionadas[0]
	var c2 := cartas_seleccionadas[1]
	var jugador_actual := turn_manager.obtener_turno()

	if c1.id_pareja == c2.id_pareja:
		var idx1 = cartas_en_mesa.find(c1)
		var idx2 = cartas_en_mesa.find(c2)
		
		if jugador_actual == 1:
			puntos_j1 += 1
		else:
			puntos_j2 += 1
		parejas_encontradas += 1
		
		rpc("sync_match_success", idx1, idx2, jugador_actual, puntos_j1, puntos_j2, contador_turnos, parejas_encontradas)
		
		if parejas_encontradas == parejas_totales:
			rpc("sync_fin_del_juego")
	else:
		var idx1 = cartas_en_mesa.find(c1)
		var idx2 = cartas_en_mesa.find(c2)
		rpc("sync_match_fail", idx1, idx2)

@rpc("authority", "call_local", "reliable")
func sync_match_success(idx1: int, idx2: int, jugador: int, p1: int, p2: int, turnos: int, pares: int) -> void:
	puntos_j1 = p1
	puntos_j2 = p2
	contador_turnos = turnos
	parejas_encontradas = pares
	
	ui_manager.mostrar_par_encontrado(jugador)
	ui_manager.actualizar_puntos(puntos_j1, puntos_j2, contador_turnos)

	_animar_par_exito(idx1, idx2)

func _animar_par_exito(idx1: int, idx2: int) -> void:
	await get_tree().create_timer(0.4).timeout
	audio_par.play()
	cartas_en_mesa[idx1].resaltar_par()
	cartas_en_mesa[idx2].resaltar_par()
	
	if GameData.my_role == GameData.Role.SERVER:
		cartas_seleccionadas.clear()
		if parejas_encontradas < parejas_totales:
			rpc("sync_mostrar_tira_otra_vez")

@rpc("authority", "call_local", "reliable")
func sync_mostrar_tira_otra_vez() -> void:
	ui_manager.mostrar_tira_otra_vez()

@rpc("authority", "call_local", "reliable")
func sync_match_fail(idx1: int, idx2: int) -> void:
	ui_manager.mostrar_fallo()
	_animar_par_fallo(idx1, idx2)

func _animar_par_fallo(idx1: int, idx2: int) -> void:
	await get_tree().create_timer(1.0).timeout
	cartas_en_mesa[idx1].ocultar_carta()
	cartas_en_mesa[idx2].ocultar_carta()
	
	if GameData.my_role == GameData.Role.SERVER:
		cartas_seleccionadas.clear()
		turn_manager.cambiar_turno()

# ── TURNO ──
func _on_turno_cambiado(jugador: int) -> void:
	if GameData.my_role == GameData.Role.SERVER:
		rpc("sync_turn", jugador, puntos_j1, puntos_j2, contador_turnos)

@rpc("authority", "call_local", "reliable")
func sync_turn(jugador: int, p1: int, p2: int, turnos: int) -> void:
	puntos_j1 = p1
	puntos_j2 = p2
	contador_turnos = turnos
	ui_manager.mostrar_turno(jugador)
	ui_manager.actualizar_puntos(puntos_j1, puntos_j2, contador_turnos)

# ── FIN ──
@rpc("authority", "call_local", "reliable")
func sync_fin_del_juego() -> void:
	juego_terminado = true
	ui_manager.mostrar_fin(puntos_j1, puntos_j2)

func _on_boton_reiniciar_pressed() -> void:
	# El botón ahora dice "REVANCHA"
	ui_manager.mostrar_esperando_oponente()
	rpc_id(1, "votar_revancha")

@rpc("any_peer", "call_remote", "reliable")
func votar_revancha() -> void:
	if GameData.my_role == GameData.Role.SERVER:
		var sender = multiplayer.get_remote_sender_id()
		# Opcional: Validar que el remitente es un cliente válido, pero para simplificar solo sumamos
		rematch_votos += 1
		# Si hay 2 votos, se reinicia la partida
		if rematch_votos >= 2:
			rpc("sync_reiniciar")

@rpc("authority", "call_local", "reliable")
func sync_reiniciar() -> void:
	_reiniciar_partida_local()

func _reiniciar_partida_local() -> void:
	# Reseteamos variables de estado
	juego_terminado = false
	tiempo_juego = 0.0
	puntos_j1 = 0
	puntos_j2 = 0
	parejas_encontradas = 0
	contador_turnos = 0
	cartas_seleccionadas.clear()
	rematch_votos = 0
	
	# Reseteamos la transformación visual para que no empiece desfasado
	grid_container.rotation = 0
	grid_container.scale = Vector2(1, 1)
	
	# Limpiamos UI
	ui_manager.actualizar_puntos(0, 0, 0)
	ui_manager.boton_reiniciar.hide()
	ui_manager.boton_salir.show() # Mantener visible al reiniciar
	ui_manager.texto_tiempo.modulate = Color.WHITE
	
	# Limpiamos tablero físicamente
	for carta in cartas_en_mesa:
		if is_instance_valid(carta):
			carta.queue_free()
	cartas_en_mesa.clear()
	
	# Si soy el Servidor Dedicado, genero el nuevo tablero y reseteo el TurnManager
	if GameData.my_role == GameData.Role.SERVER:
		turn_manager.iniciar()
		# El servidor avisa del nuevo turno a todos
		rpc("sync_turn", turn_manager.obtener_turno(), 0, 0, 0)
		generar_tablero()
	
# --- AJUSTES DE SONIDO ---
func _on_btn_ajustes_pressed() -> void:
	panel_ajustes.show()

func _on_btn_cerrar_ajustes_pressed() -> void:
	panel_ajustes.hide()

func _on_volumen_cambiado(valor: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if valor == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(valor))


func _on_button_pressed() -> void:
	pass # Replace with function body.
	
func _on_btn_volver_menu_pressed() -> void:
	# Antes de salir, cerramos la conexión si somos el host o cliente
	multiplayer.multiplayer_peer = null
	# Volvemos al menú
	get_tree().change_scene_to_file("res://Escenas/Menu.tscn")

# --- MANEJO DE DESCONEXIÓN ---
func _on_peer_disconnected(_id: int) -> void:
	# Si alguien se desconecta (normalmente el cliente si somos host)
	juego_terminado = true
	ui_manager.texto_estado.text = "El oponente ha abandonado..."
	ui_manager.texto_estado.modulate = Color.RED
	ui_manager.boton_reiniciar.hide()

func _on_server_disconnected() -> void:
	# Si el servidor se cierra (el host salió)
	juego_terminado = true
	ui_manager.texto_estado.text = "El Host ha cerrado la partida..."
	ui_manager.texto_estado.modulate = Color.RED
	ui_manager.boton_reiniciar.hide()
