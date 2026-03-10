extends TextureButton

class_name Carta

signal carta_seleccionada(carta)

var id_pareja := 0
var esta_volteada := false

@onready var sprite_frente: Sprite2D = $Sprite2D

func _ready() -> void:
	pressed.connect(_al_presionar)
	sprite_frente.visible = false

func configurar(id: int, textura_imagen: Texture2D) -> void:
	id_pareja = id
	sprite_frente.texture = textura_imagen

func _al_presionar() -> void:
	if not esta_volteada:
		emit_signal("carta_seleccionada", self)

func voltear() -> void:
	esta_volteada = true
	disabled = true
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.1)
	tween.tween_callback(func(): sprite_frente.visible = true)
	tween.tween_property(self, "scale:x", 1.0, 0.1)

func ocultar_carta() -> void:
	esta_volteada = false
	disabled = false
	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, 0.1)
	tween.tween_callback(func(): sprite_frente.visible = false)
	tween.tween_property(self, "scale:x", 1.0, 0.1)

func resaltar_par() -> void:
	# Destello dorado al encontrar par
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.4, 1.2, 0.4), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)
