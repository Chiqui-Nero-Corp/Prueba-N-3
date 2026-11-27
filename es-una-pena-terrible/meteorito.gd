extends Area2D

const SONIDO_IMPACTO = preload("res://EXPLOTAR.mp3")

@export var volumen_impacto_db: float = -2.0
@export var velocidad_inicial: float = 400.0
@export var aceleracion: float = 4800.0
@export var velocidad_maxima: float = 8000.0

var velocidad_actual: float = 0.0
var destino: Vector2 = Vector2.ZERO
var daño: float = 1.0
var explo = preload("res://explo.tscn")
var ha_chocado: bool = false

func inicializar(pos_destino: Vector2) -> void:
	destino = pos_destino
	global_position = Vector2(get_viewport_rect().size.x / 2, -50)
	velocidad_actual = velocidad_inicial

	# Acá se mide cuán bajo se hizo el clic, y por ende, cuánto va a ser su daño
	var alto_pantalla = get_viewport_rect().size.y
	var proporcion = pos_destino.y / alto_pantalla
	daño = max(0.5, 2.0 - (proporcion * 1.5))

	var gestor := get_tree().get_first_node_in_group("gestor_partida")
	if gestor != null and "multiplicador_dano_buff" in gestor:
		daño *= gestor.multiplicador_dano_buff

	print("Daño del meteorito: ", daño)

func _process(delta: float) -> void:
	if ha_chocado:
		return

	# Aplicamos v = v0 + a * t (con un tope máximo)
	velocidad_actual = min(velocidad_actual + aceleracion * delta, velocidad_maxima)

	var distancia_restante = global_position.distance_to(destino)
	var avance = velocidad_actual * delta

	# Si en este frame va a alcanzar o superar el destino, explota directo en él
	if avance >= distancia_restante:
		global_position = destino
		explotar(destino)
		return

	var direccion = (destino - global_position).normalized()
	global_position += direccion * avance

func _on_area_entered(area: Area2D) -> void:
	if ha_chocado:
		return

	if area.has_method("recibir_daño"):
		area.recibir_daño(daño)

	explotar(global_position + Vector2(0, 30))

func _reproducir_sonido_impacto() -> void:
	if SONIDO_IMPACTO == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = SONIDO_IMPACTO
	player.volume_db = volumen_impacto_db
	player.pitch_scale = randf_range(0.92, 1.08)
	get_tree().root.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func explotar(posicion: Vector2) -> void:
	ha_chocado = true
	_reproducir_sonido_impacto()

	var instancia_explo = explo.instantiate()
	instancia_explo.global_position = posicion - Vector2(20, -20)
	get_tree().current_scene.add_child(instancia_explo)

	var timer_destruir = Timer.new()
	timer_destruir.wait_time = 0.4
	timer_destruir.one_shot = true
	timer_destruir.timeout.connect(func(): instancia_explo.queue_free())
	instancia_explo.add_child(timer_destruir)
	timer_destruir.start()

	queue_free()
