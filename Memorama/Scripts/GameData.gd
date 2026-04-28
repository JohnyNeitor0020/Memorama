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

func _ready() -> void:
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
