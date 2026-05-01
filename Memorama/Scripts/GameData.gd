extends Node

enum Role { SERVER, P1, P2, SPECTATOR, NONE }

# Datos que viajan del menú al juego
var nombre_j1 := "Nombre"
var nombre_j2 := "Jugador 2"
var parejas := 8  # 8 = fácil, 12 = normal, 16 = difícil

# Variables de entorno y red
var server_port: int = 10000
var server_bind_ip: String = "*"
var client_connect_ip: String = "127.0.0.1"
var server_url: String = "memorama-xvwq.onrender.com"  # URL de Render por defecto
var connection_mode: String = "remote"  # Por defecto conectar a la nube

# Variables de red multijugador
var my_role: Role = Role.NONE
var peer_id: int = 1
var p1_peer_id: int = 0
var p2_peer_id: int = 0
var nombres_recibidos := 0
var current_scene := "Menu" # Para que los espectadores sepan a dónde ir

func reset_server_state() -> void:
	p1_peer_id = 0
	p2_peer_id = 0
	nombres_recibidos = 0
	nombre_j1 = "Jugador 1"
	nombre_j2 = "Jugador 2"
	current_scene = "Menu"

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Si un espectador entra tarde, el servidor le avisa dónde estamos
	multiplayer.peer_connected.connect(func(id):
		if my_role == Role.SERVER and current_scene == "Juego":
			rpc_id(id, "force_scene_change", "res://Escenas/Juego.tscn")
	)
	
	_cargar_env_local()
	
	if OS.has_environment("PORT"):
		server_port = OS.get_environment("PORT").to_int()
	if OS.has_environment("DEFAULT_IP"):
		server_bind_ip = OS.get_environment("DEFAULT_IP")
	if OS.has_environment("CLIENT_IP"):
		client_connect_ip = OS.get_environment("CLIENT_IP")
	if OS.has_environment("SERVER_URL"):
		server_url = OS.get_environment("SERVER_URL")
	if OS.has_environment("MODE"):
		connection_mode = OS.get_environment("MODE")

func _cargar_env_local() -> void:
	# En producción (ej. Docker/Render), las variables ya estarán en el OS.
	# Esta función solo lee el archivo .env para pruebas locales en Godot.
	if FileAccess.file_exists("res://.env"):
		var file = FileAccess.open("res://.env", FileAccess.READ)
		if file:
			while not file.eof_reached():
				var line = file.get_line().strip_edges()
				if line != "" and not line.begins_with("#"):
					var partes = line.split("=", true, 1)
					if partes.size() == 2:
						# Solo aplicamos si la variable no fue inyectada previamente por el OS
						if not OS.has_environment(partes[0].strip_edges()):
							OS.set_environment(partes[0].strip_edges(), partes[1].strip_edges())
			file.close()

func _on_peer_connected(id: int) -> void:
	if my_role == Role.SERVER:
		if p1_peer_id == 0:
			p1_peer_id = id
		elif p2_peer_id == 0:
			p2_peer_id = id

func _on_peer_disconnected(id: int) -> void:
	if my_role == Role.SERVER:
		if id == p1_peer_id:
			p1_peer_id = 0
			nombres_recibidos = max(0, nombres_recibidos - 1)
		elif id == p2_peer_id:
			p2_peer_id = 0
			nombres_recibidos = max(0, nombres_recibidos - 1)
		
		# Si ya no queda nadie, el servidor vuelve al menú para estar limpio
		if p1_peer_id == 0 and p2_peer_id == 0:
			reset_server_state()
			get_tree().change_scene_to_file("res://Escenas/Menu.tscn")

@rpc("authority", "reliable")
func force_scene_change(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
