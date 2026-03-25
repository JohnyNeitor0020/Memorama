extends Node2D

var dificultad_seleccionada := 8

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

func _ready() -> void:
	_crear_estilos()
	_seleccionar_dificultad(8)
	slider_volumen.value_changed.connect(_on_volumen_cambiado)
	slider_volumen.value = 0.5
	
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

func _on_btn_jugar_pressed() -> void:
	GameData.nombre_j1 = input_j1.text.strip_edges()
	GameData.nombre_j2 = input_j2.text.strip_edges()
	if GameData.nombre_j1 == "":
		GameData.nombre_j1 = "Jugador 1"
	if GameData.nombre_j2 == "":
		GameData.nombre_j2 = "Jugador 2"
	GameData.parejas = dificultad_seleccionada
	get_tree().change_scene_to_file("res://Escenas/Juego.tscn")

func _on_btn_salir_pressed() -> void:
	get_tree().quit()
	
# --- AJUSTES DE SONIDO ---

# Abrir el panel
func _on_btn_ajustes_pressed() -> void:
	panel_ajustes.show()
	# Ocultamos lo demás para que no estorbe
	fila_j1.hide()
	fila_j2.hide()
	panel_dificultad.hide()
	BtnJugar.hide()

# Cerrar el panel
func _on_btn_cerrar_ajustes_pressed() -> void:
	panel_ajustes.hide()
	# Volvemos a mostrar todo como estaba
	fila_j1.show()
	fila_j2.show()
	panel_dificultad.show()
	BtnJugar.show()

# Ajustar el volumen maestro de todo el juego
func _on_volumen_cambiado(valor: float) -> void:
	# Godot usa decibelios (dB). linear_to_db convierte el 0 a 1 del slider a decibelios correctos.
	var bus_index := AudioServer.get_bus_index("Master")
	
	if valor == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(valor))


func _on_button_pressed() -> void:
	pass # Replace with function body.
