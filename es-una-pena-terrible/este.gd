extends Area2D

var velocidad: float = 120.0
var direccion: int = 1
var rebotes_restantes: int = 2
var es_trampolin: bool = true
var vida: float = 3.0
var daño_a_otros: float = 2.0

func configurar(pos: Vector2, dir: int) -> void:
	global_position = pos
	direccion = dir
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = (dir == -1)

func _ready() -> void:
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position.x += velocidad * direccion * delta
	
	var ancho := get_viewport_rect().size.x
	if global_position.x < -100.0 or global_position.x > ancho + 100.0:
		queue_free()

func consumir_rebote_meteorito() -> void:
	# Se llama desde meteorito.gd cuando rebota en este dino
	rebotes_restantes -= 1
	print("Rebotes restantes del trampolín: ", rebotes_restantes)
	
	if rebotes_restantes <= 0:
		es_trampolin = false
		modulate = Color(1.0, 1.0, 1.0) # Vuelve a su color normal de dino común

func recibir_daño(cantidad: float) -> void:
	# Mientras sea trampolín, los meteoritos rebotan en vez de dañarlo
	if es_trampolin:
		return
	
	# Ya como dino común, recibe daño normal
	vida -= cantidad
	if vida <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == self:
		return
	
	# Golpea a otros dinosaurios comunes (evita golpear meteoritos o a sí mismo)
	if area.has_method("recibir_daño") and area.get("es_trampolin") == null:
		area.recibir_daño(daño_a_otros)
