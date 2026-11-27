extends Node2D

@export var ruta_video: String = "res://intro.ogv"
@export var pausar_juego_mientras_reproduce: bool = false

@onready var boton_video: Button = $CanvasLayer/BotonVideo
@onready var reproductor_video: VideoStreamPlayer = $CanvasLayer/ReproductorVideo

func _ready() -> void:
	reproductor_video.visible = false
	boton_video.pressed.connect(_on_boton_video_pressed)
	reproductor_video.finished.connect(_on_video_terminado)

func _on_boton_video_pressed() -> void:
	if reproductor_video.stream == null and ruta_video != "" and ResourceLoader.exists(ruta_video):
		reproductor_video.stream = load(ruta_video)

	reproductor_video.visible = true
	reproductor_video.play()

	if pausar_juego_mientras_reproduce:
		get_tree().paused = true
		# Asegúrate de poner Process Mode -> Always en CanvasLayer / ReproductorVideo si pausas el árbol

func _on_video_terminado() -> void:
	reproductor_video.stop()
	reproductor_video.visible = false
	if pausar_juego_mientras_reproduce:
		get_tree().paused = false
