extends Area2D

var destino: Vector2 = Vector2.ZERO
var velocidad: float = 600.0
var daño: float = 2.0

func inicializar(pos_destino: Vector2) -> void:
	destino = pos_destino
	# Nace arriba en el centro de la pantalla
	global_position = Vector2(get_viewport_rect().size.x / 2, -50)
	
	# SIMULACIÓN DE LA ATMÓSFERA:
	var alto_pantalla = get_viewport_rect().size.y
	var proporcion = pos_destino.y / alto_pantalla # Mide qué tan abajo fue el clic
	daño = max(0.5, 2.0 - (proporcion * 1.5))      # Menos daño si haces clic más abajo
	print("Daño del meteorito: ", daño)

func _process(delta: float) -> void:
	# Movimiento en línea recta directa hacia el objetivo (sin gravedad ni parábolas)
	var direccion = (destino - global_position).normalized()
	global_position += direccion * velocidad * delta
	
	# Si llega cerca del lugar donde hiciste clic, desaparece
	if global_position.distance_to(destino) < 10.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("recibir_daño"):
		area.recibir_daño(daño)
	queue_free()
