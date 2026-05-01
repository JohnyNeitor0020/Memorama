extends Node2D

# Las variables de red ahora vienen de GameData (que lee de .env)

var dificultad_seleccionada := 8
var mi_nombre := ""

@onready var BtnJugar: Control =$CanvasLayer/BtnJugar
@onready var fila_j1: Control = $CanvasLayer/FilaJ1
@onready var fila_j2: Control = $CanvasLayer/FilaJ2
@onready var panel_dificultad: Control = $CanvasLayer/PanelDificultad
@onready var panel_ajustes: Panel = $CanvasLayer/PanelAjustes
@onready var slider_volumen: HSlider = $CanvasLayer/PanelAjustes/HSlider
@onready var input_j1: LineEdit = $CanvasLayer/FilaJ1/InputJ1
@onready var input_j2: LineEdit = $CanvasLayer/FilaJ2/InputJ2
@onready var btn_facil: Button = $CanvasLayer/PanelDificultad/MarginDif/VBoxDif/HBoxBotones/BtnFacil
@onready var btn_normal: Button = $CanvasLayer/PanelDificultad/MarginDif/VBoxDif/HBoxBotones/BtnNormal
@onready var btn_dificil: Button = $CanvasLayer/PanelDificultad/MarginDif/VBoxDif/HBoxBotones/BtnDificil

var estilo_off: StyleBoxFlat
var estilo_on: StyleBoxFlat
var vbox_botones: VBoxContainer
var panel_espera: Panel

func _ready() -> void:
	name = "Menu" # Forzar nombre para que el servidor y cliente coincidan en las rutas de RPC
	_crear_estilos()
	_crear_panel_espera() # Inicializar el modal de espera
	_seleccionar_dificultad(8)
	slider_volumen.value_changed.connect(_on_volumen_cambiado)
	slider_volumen.value = 0.5
	
	# Ocultamos la fila 2 porque es online
	fila_j2.hide()
	input_j1.placeholder_text = "Ingresa tu nombre"
	# Forzar teclado en móviles al tocar el input
	input_j1.focus_entered.connect(func(): DisplayServer.virtual_keyboard_show(""))
	
	# Señales nativas de la API Multijugador de Godot
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	_crear_botones_multijugador()
	
	# AUTO-HOST PARA SERVIDORES (Render)
	# Si detectamos que el juego corre sin interfaz gráfica (modo headless), 
	# simulamos el clic en "Crear Partida" inmediatamente para abrir el puerto.
	if DisplayServer.get_name() == "headless":
		print("Modo servidor (headless) detectado. Auto-hosteando...")
		call_deferred("_on_host_pressed")

func _crear_botones_multijugador() -> void:
	# 1. Ocultar el botón original
	BtnJugar.hide()
	
	# 2. Crear VBoxContainer para alinear los botones dinámicos al centro
	vbox_botones = VBoxContainer.new()
	# Lo posicionamos un poco abajo del centro de la pantalla (ajustable)
	vbox_botones.position = Vector2(get_viewport_rect().size.x / 2.0 - 125, get_viewport_rect().size.y - 200)
	vbox_botones.custom_minimum_size = Vector2(250, 120)
	vbox_botones.add_theme_constant_override("separation", 15)
	$CanvasLayer.add_child(vbox_botones)
	
	# 3. Crear Botón Host (solo en modo local, en remoto el servidor ya está en Render)
	if GameData.connection_mode != "remote":
		var btn_host = Button.new()
		btn_host.text = "Crear Partida"
		btn_host.custom_minimum_size = Vector2(250, 50)
		btn_host.add_theme_stylebox_override("normal", estilo_off)
		btn_host.add_theme_stylebox_override("hover", estilo_on)
		btn_host.add_theme_font_size_override("font_size", 20)
		btn_host.pressed.connect(_on_host_pressed)
		vbox_botones.add_child(btn_host)
	
	# 4. Crear Botón Join
	var btn_join = Button.new()
	btn_join.text = "Unirse a Partida"
	btn_join.custom_minimum_size = Vector2(250, 50)
	# Reutilizamos tus estilos del casino
	btn_join.add_theme_stylebox_override("normal", estilo_off)
	btn_join.add_theme_stylebox_override("hover", estilo_on)
	btn_join.add_theme_font_size_override("font_size", 20)
	btn_join.pressed.connect(_on_join_pressed)
	vbox_botones.add_child(btn_join)

func _crear_panel_espera() -> void:
	# Contenedor principal de pantalla completa
	panel_espera = Panel.new()
	panel_espera.hide()
	
	# Estilo: Fondo oscuro para ocultar el menú
	var estilo_fondo = StyleBoxFlat.new()
	estilo_fondo.bg_color = Color(0.01, 0.08, 0.04, 1.0) # Verde casino muy sólido
	panel_espera.add_theme_stylebox_override("panel", estilo_fondo)
	panel_espera.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Centro del contenido
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_espera.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)
	
	# Cuadro de mensaje (el que tenías pero más grande)
	var box = Panel.new()
	box.custom_minimum_size = Vector2(500, 250)
	var estilo_box = StyleBoxFlat.new()
	estilo_box.bg_color = Color(0.04, 0.15, 0.06, 1.0)
	estilo_box.border_width_left = 3
	estilo_box.border_width_top = 3
	estilo_box.border_width_right = 3
	estilo_box.border_width_bottom = 3
	estilo_box.border_color = Color(0.7, 0.56, 0.18)
	estilo_box.corner_radius_top_left = 20
	estilo_box.corner_radius_top_right = 20
	estilo_box.corner_radius_bottom_left = 20
	estilo_box.corner_radius_bottom_right = 20
	box.add_theme_stylebox_override("panel", estilo_box)
	vbox.add_child(box)
	
	# Texto
	var label = Label.new()
	label.text = "SALA DE ESPERA\nCONECTANDO AL CASINO...\nESPERANDO RIVAL"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	box.add_child(label)
	
	# Botón Cancelar
	var btn_cancelar = Button.new()
	btn_cancelar.text = "CANCELAR Y REGRESAR"
	btn_cancelar.custom_minimum_size = Vector2(300, 60)
	btn_cancelar.add_theme_stylebox_override("normal", estilo_off)
	btn_cancelar.add_theme_stylebox_override("hover", estilo_on)
	btn_cancelar.add_theme_font_size_override("font_size", 18)
	btn_cancelar.pressed.connect(_on_cancel_pressed)
	vbox.add_child(btn_cancelar)
	
	$CanvasLayer.add_child(panel_espera)

func _on_cancel_pressed() -> void:
	# Desconectar multijugador si existe
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Resetear variables
	GameData.my_role = GameData.Role.NONE
	
	# Volver al menú
	panel_espera.hide()
	vbox_botones.show()
	print("Conexión cancelada por el usuario")


func _crear_estilos() -> void:
	estilo_off = StyleBoxFlat.new()
	estilo_off.bg_color = Color(0.05, 0.21, 0.09, 0.95)
	estilo_off.border_color = Color(0.70, 0.56, 0.18)
	estilo_off.set_border_width_all(2)
	estilo_off.set_corner_radius_all(6)

	estilo_on = StyleBoxFlat.new()
	estilo_on.bg_color = Color(0.50, 0.33, 0.06)
	estilo_on.border_color = Color(0.96, 0.84, 0.30)
	estilo_on.set_border_width_all(2)
	estilo_on.set_corner_radius_all(6)
	estilo_on.shadow_color = Color(0.96, 0.84, 0.30, 0.25)
	estilo_on.shadow_size = 4

func _seleccionar_dificultad(parejas: int) -> void:
	dificultad_seleccionada = parejas
	for btn in [btn_facil, btn_normal, btn_dificil]:
		btn.add_theme_stylebox_override("normal", estilo_off)
		btn.add_theme_stylebox_override("hover", estilo_off)
		btn.add_theme_color_override("font_color", Color(0.90, 0.82, 0.52))
	var activo := btn_facil if parejas == 8 else (btn_normal if parejas == 12 else btn_dificil)
	activo.add_theme_stylebox_override("normal", estilo_on)
	activo.add_theme_stylebox_override("hover", estilo_on)
	activo.add_theme_color_override("font_color", Color(1.0, 0.95, 0.62))

func _on_btn_facil_pressed() -> void:
	_seleccionar_dificultad(8)

func _on_btn_normal_pressed() -> void:
	_seleccionar_dificultad(12)

func _on_btn_dificil_pressed() -> void:
	_seleccionar_dificultad(16)

# Este método se ha eliminado porque validamos localmente en los botones

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
	
# --- AJUSTES DE SONIDO ---
func _on_btn_ajustes_pressed() -> void:
	panel_ajustes.show()
	panel_ajustes.move_to_front()
	fila_j1.hide()
	fila_j2.hide()
	panel_dificultad.hide()
	if vbox_botones: vbox_botones.hide()

func _on_btn_cerrar_ajustes_pressed() -> void:
	panel_ajustes.hide()
	fila_j1.show()
	# fila_j2 se mantiene oculto porque es modo online (solo 1 nombre local)
	panel_dificultad.show()
	if vbox_botones: vbox_botones.show()

func _on_volumen_cambiado(valor: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	if valor == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(valor))

func _on_button_pressed() -> void:
	pass

# --- RED MULTIJUGADOR ---
func _on_host_pressed() -> void:
	# El host dedicado no juega, así que no necesita leer su nombre.
	GameData.parejas = dificultad_seleccionada

	var peer = WebSocketMultiplayerPeer.new()
	# Usamos GameData.server_port porque ya lee automáticamente la variable PORT de Render
	var error = peer.create_server(GameData.server_port) 
	if error != OK:
		print("Error al crear el servidor: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	GameData.my_role = GameData.Role.SERVER
	GameData.peer_id = 1
	GameData.p1_peer_id = 0
	GameData.p2_peer_id = 0
	nombres_recibidos = 0
	GameData.current_scene = "Menu" # Para que los espectadores sepan a dónde ir
	_mostrar_esperando_oponente()

func _mostrar_esperando_oponente() -> void:
	# Ocultar elementos del menú para limpiar la vista
	fila_j1.hide()
	panel_dificultad.hide()
	vbox_botones.hide()
	
	# 1. Crear un Panel estilizado para el mensaje
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 250)
	# Reutilizamos el estilo oscuro con borde dorado del casino
	panel.add_theme_stylebox_override("panel", estilo_off)
	
	# 2. Contenedor de márgenes interno
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	# 3. VBox para organizar textos y botón
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 25)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# 4. Título Brillante
	var lbl_titulo = Label.new()
	lbl_titulo.text = "¡SALA DE ESPERA!"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 34)
	lbl_titulo.add_theme_color_override("font_color", Color(0.96, 0.84, 0.30)) # Dorado
	vbox.add_child(lbl_titulo)
	
	# 5. Texto de estado con animación de puntos (simulada)
	var lbl_espera = Label.new()
	lbl_espera.text = "Esperando a que un oponente se una..."
	lbl_espera.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_espera.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl_espera)
	
	# 6. Botón para cancelar y volver atrás
	var btn_cancelar = Button.new()
	btn_cancelar.text = "CANCELAR"
	btn_cancelar.custom_minimum_size = Vector2(180, 45)
	btn_cancelar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cancelar.add_theme_stylebox_override("normal", estilo_off)
	btn_cancelar.add_theme_stylebox_override("hover", estilo_on)
	btn_cancelar.add_theme_color_override("font_color", Color(0.96, 0.84, 0.30))
	# Si cancela, cerramos el servidor de red y recargamos la escena
	btn_cancelar.pressed.connect(func(): 
		if multiplayer.multiplayer_peer:
			multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		get_tree().reload_current_scene()
	)
	vbox.add_child(btn_cancelar)
	
	# 7. Centrado absoluto en pantalla
	$CanvasLayer.add_child(panel)
	# Forzamos la actualización para obtener el tamaño real si es posible, o usamos el mínimo
	var screen_size = get_viewport_rect().size
	panel.global_position = (screen_size / 2.0) - (panel.custom_minimum_size / 2.0)

func _on_join_pressed() -> void:
	mi_nombre = input_j1.text.strip_edges()
	if mi_nombre == "":
		mi_nombre = "Jugador"

	# Mostrar el cuadro de espera con diseño premium
	panel_espera.show()
	vbox_botones.hide()

	var peer = WebSocketMultiplayerPeer.new()
	
	# Usamos la URL de GameData (que viene del .env) asegurando el protocolo wss:// para iOS
	var url = "wss://" + GameData.server_url
	
	print("Conectando a: ", url)
	var error = peer.create_client(url)
	if error != OK:
		print("Error al unirse al servidor: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	GameData.my_role = GameData.Role.NONE # Esperamos a que el servidor nos asigne un rol
	print("Conectando al servidor...")

func _on_connected_to_server() -> void:
	print("Conectado exitosamente al servidor!")
	GameData.peer_id = multiplayer.get_unique_id()
	# Mandamos nuestro nombre Y la dificultad elegida
	rpc_id(1, "register_client_name", mi_nombre, dificultad_seleccionada)

@rpc("any_peer", "call_remote", "reliable")
func register_client_name(client_name: String, dificultad: int) -> void:
	if GameData.my_role == GameData.Role.SERVER:
		var sender_id = multiplayer.get_remote_sender_id()
		
		# El primer jugador que se registra define la dificultad global
		if GameData.nombres_recibidos == 0:
			GameData.parejas = dificultad
			print("Dificultad fijada por el primer jugador: ", dificultad)
		
		if sender_id == GameData.p1_peer_id:
			GameData.nombre_j1 = client_name
			GameData.nombres_recibidos += 1
		elif sender_id == GameData.p2_peer_id:
			GameData.nombre_j2 = client_name
			GameData.nombres_recibidos += 1
		
		# Si ya tenemos a los dos, iniciamos
		if GameData.nombres_recibidos >= 2:
			rpc("start_game_dedicated", GameData.parejas, GameData.nombre_j1, GameData.nombre_j2, GameData.p1_peer_id, GameData.p2_peer_id)


@rpc("authority", "call_local", "reliable")
func start_game_dedicated(parejas: int, n1: String, n2: String, p1_id: int, p2_id: int) -> void:
	GameData.parejas = parejas
	GameData.nombre_j1 = n1
	GameData.nombre_j2 = n2
	GameData.p1_peer_id = p1_id
	GameData.p2_peer_id = p2_id
	
	if GameData.my_role != GameData.Role.SERVER:
		var my_id = multiplayer.get_unique_id()
		if my_id == p1_id:
			GameData.my_role = GameData.Role.P1
		elif my_id == p2_id:
			GameData.my_role = GameData.Role.P2
		else:
			GameData.my_role = GameData.Role.SPECTATOR
			
	if GameData.my_role == GameData.Role.SERVER:
		GameData.current_scene = "Juego"
			
	get_tree().change_scene_to_file("res://Escenas/Juego.tscn")
