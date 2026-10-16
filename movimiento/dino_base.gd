extends CharacterBody2D

var velocidad = 200
var direccion = 1
var tiempo_cambio = 0.0

func _ready():
	_definir_proximo_cambio()

func _process(delta):
	position.x += velocidad * direccion * delta
	tiempo_cambio -= delta
	if tiempo_cambio <= 0:
		_cambiar_movimiento_aleatorio()

func _definir_proximo_cambio():
	tiempo_cambio = randf_range(0.5, 2.0)

func _cambiar_movimiento_aleatorio():
	direccion = 1 if randf() > 0.5 else -1
	_definir_proximo_cambio()

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
