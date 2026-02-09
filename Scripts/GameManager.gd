extends Node2D

# Referencia a la escena de la carta para duplicarla
@export var escena_carta: PackedScene 
# Lista de texturas (fotos) que arrastrarás en el inspector
@export var texturas_cartas: Array[Texture2D] 

var cartas_en_mesa = []
var cartas_seleccionadas = [] # Buffer para guardar las 2 cartas volteadas
var turno_jugador = 1 # 1 o 2

func _ready():
	generar_tablero()

func generar_tablero():
	# Lógica para crear pares
	var ids = []
	for i in range(texturas_cartas.size()):
		ids.append(i)
		ids.append(i) # Añadimos el par
	
	ids.shuffle() # Barajar (IMPORTANTE para fase 2 y 3)
	
	# Crear las cartas visualmente
	for id in ids:
		var nueva_carta = escena_carta.instantiate()
		$CanvasLayer/GridContainer.add_child(nueva_carta)
		nueva_carta.configurar(id, texturas_cartas[id])
		# Conectar la señal de la carta a este script
		nueva_carta.carta_seleccionada.connect(_on_carta_tocada)
		cartas_en_mesa.append(nueva_carta)

func _on_carta_tocada(carta):
	# Regla: No puedes voltear más de 2 cartas
	if cartas_seleccionadas.size() >= 2:
		return

	carta.voltear()
	cartas_seleccionadas.append(carta)
	
	if cartas_seleccionadas.size() == 2:
		verificar_par()

func verificar_par():
	var c1 = cartas_seleccionadas[0]
	var c2 = cartas_seleccionadas[1]
	
	if c1.id_pareja == c2.id_pareja:
		print("¡Es un par!")
		cartas_seleccionadas.clear()
		# Aquí sumar puntos al Jugador actual
	else:
		print("No es par, espera...")
		# Timer pequeño para ver el error
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
	print("Turno del Jugador: ", turno_jugador)
