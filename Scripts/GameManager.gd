extends Node2D

# --- CONFIGURACIÓN ---
@export var escena_carta: PackedScene 
@export var texturas_cartas: Array[Texture2D] 

# --- REFERENCIAS UI ---
@onready var texto_estado = $CanvasLayer/TextoEstado
@onready var texto_tiempo = $CanvasLayer/TextoTiempo # <--- NUEVO
@onready var texto_puntos = $CanvasLayer/TextoPuntos # <--- NUEVO
@onready var boton_reiniciar = $CanvasLayer/BotonReiniciar
# --- VARIABLES DE JUEGO ---
var cartas_en_mesa = []
var cartas_seleccionadas = [] 
var turno_jugador = 1 

# --- ESTADÍSTICAS ---
var puntos_j1 = 0
var puntos_j2 = 0
var parejas_encontradas = 0
var parejas_totales = 0
var tiempo_juego = 0.0
var juego_terminado = false
var contador_turnos = 0

func _ready():
	parejas_totales = texturas_cartas.size()
	actualizar_interfaz()
	generar_tablero()

func _process(delta):
	# El reloj solo avanza si el juego NO ha terminado
	if not juego_terminado:
		tiempo_juego += delta
		# Formato de minutos y segundos (00:00)
		var mins = int(tiempo_juego / 60)
		var segs = int(tiempo_juego) % 60
		texto_tiempo.text = "Tiempo: %02d:%02d" % [mins, segs]

func generar_tablero():
	var ids = []
	for i in range(parejas_totales):
		ids.append(i)
		ids.append(i)
	
	ids.shuffle()
	
	for id in ids:
		var nueva_carta = escena_carta.instantiate()
		$CanvasLayer/GridContainer.add_child(nueva_carta)
		
		if nueva_carta.has_method("configurar"):
			nueva_carta.configurar(id, texturas_cartas[id])
		
		if nueva_carta.has_signal("carta_seleccionada"):
			nueva_carta.carta_seleccionada.connect(_on_carta_tocada)
			
		cartas_en_mesa.append(nueva_carta)

func _on_carta_tocada(carta):
	if cartas_seleccionadas.size() >= 2 or juego_terminado:
		return
	
	if has_node("AudioVoltear"):
		$AudioVoltear.play()
	
	carta.voltear()
	cartas_seleccionadas.append(carta)
	
	if cartas_seleccionadas.size() == 2:
		contador_turnos += 1 # Contamos un intento
		verificar_par()

func verificar_par():
	var c1 = cartas_seleccionadas[0]
	var c2 = cartas_seleccionadas[1]
	
	if c1.id_pareja == c2.id_pareja:
		# ¡ES PAR!
		texto_estado.text = "¡PUNTO!"
		texto_estado.modulate = Color.GREEN
		
		# Sumar punto al jugador actual
		if turno_jugador == 1:
			puntos_j1 += 1
		else:
			puntos_j2 += 1
			
		parejas_encontradas += 1
		actualizar_interfaz() # Actualiza los marcadores
		
		await get_tree().create_timer(0.5).timeout
		if has_node("AudioPar"):
			$AudioPar.play()
			
		cartas_seleccionadas.clear()
		
		# ¿SE ACABÓ EL JUEGO?
		if parejas_encontradas == parejas_totales:
			fin_del_juego()
		else:
			# Si acertó, sigue tirando el mismo (opcional) o cambia
			# Aquí dejaremos que siga tirando como premio
			texto_estado.text = "¡Tira otra vez!"
			await get_tree().create_timer(1.0).timeout
			actualizar_interfaz()
		
	else:
		# FALLO
		texto_estado.text = "No coinciden..."
		texto_estado.modulate = Color.RED
		
		await get_tree().create_timer(1.0).timeout
		
		c1.ocultar()
		c2.ocultar()
		cartas_seleccionadas.clear()
		cambiar_turno()

func cambiar_turno():
	if turno_jugador == 1:
		turno_jugador = 2
	else:
		turno_jugador = 1
	actualizar_interfaz()

func actualizar_interfaz():
	# Muestra puntajes
	texto_puntos.text = "J1: %d  |  J2: %d  (Turnos: %d)" % [puntos_j1, puntos_j2, contador_turnos]
	
	# Muestra de quién es el turno (si no ha terminado)
	if not juego_terminado:
		texto_estado.text = "Turno del Jugador " + str(turno_jugador)
		if turno_jugador == 1:
			texto_estado.modulate = Color(0.2, 0.6, 1) # Azul
		else:
			texto_estado.modulate = Color(1, 0.8, 0.2) # Naranja

func fin_del_juego():
	juego_terminado = true
	texto_tiempo.modulate = Color.YELLOW
	
	var mensaje = ""
	if puntos_j1 > puntos_j2:
		mensaje = "¡GANÓ EL JUGADOR 1!"
		texto_estado.modulate = Color(0.2, 0.6, 1) # Azul
	elif puntos_j2 > puntos_j1:
		mensaje = "¡GANÓ EL JUGADOR 2!"
		texto_estado.modulate = Color(1, 0.8, 0.2) # Naranja
	else:
		mensaje = "¡EMPATE!"
		texto_estado.modulate = Color.WHITE
	
	texto_estado.text = mensaje
	
	boton_reiniciar.show() # <--- ¡Aparece el botón!
	


func _on_boton_reiniciar_pressed() -> void:
	get_tree().reload_current_scene()
