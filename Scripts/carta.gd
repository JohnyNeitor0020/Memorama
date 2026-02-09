extends TextureButton

class_name Carta

# Señal para avisarle al cerebro que nos clickearon
signal carta_seleccionada(carta)

var id_pareja = 0 # ID para saber si es par (ej: 1 con 1)
var esta_volteada = false

func _ready():
	# Conectamos el clic del propio botón
	pressed.connect(_al_presionar)
	# Escondemos la figura al inicio (se ve el reverso)
	$Sprite2D.visible = false

func configurar(id, textura_imagen):
	id_pareja = id
	$Sprite2D.texture = textura_imagen

func _al_presionar():
	if not esta_volteada:
		emit_signal("carta_seleccionada", self)

func voltear():
	esta_volteada = true
	disabled = true # Desactivar clic
	$Sprite2D.visible = true # Mostrar figura

func ocultar():
	esta_volteada = false
	disabled = false # Reactivar clic
	$Sprite2D.visible = false
