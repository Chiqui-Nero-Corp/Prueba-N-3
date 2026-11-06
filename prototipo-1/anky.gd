extends Area2D

var velocidad = 200.0
var direccion = 1
var vida: float = 2.0 # El dinosaurio ahora resiste una cantidad de daño

func configurar(pos: Vector2, dir: int) -> void:
	global_position = pos
	direccion = dir
	if dir == -1 and has_node("Sprite2D"):
		$Sprite2D.flip_h = true

func _process(delta: float) -> void:
	global_position.x += velocidad * direccion * delta
	var ancho = get_viewport_rect().size.x
	if global_position.x < -100 or global_position.x > ancho + 100:
		queue_free()

func recibir_daño(cantidad: float) -> void:
	# Resta vida según el daño que recibe del meteorito
	vida -= cantidad
	# Si la vida llega a cero o menos, el dinosaurio se muere
	if vida <= 0:
		queue_free()
