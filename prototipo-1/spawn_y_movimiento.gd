extends Node2D

const ANKY = preload("res://anky.tscn")
const METEORITO = preload("res://meteorito.tscn")
var clic_anterior = false

func _ready() -> void:
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_spawn_anky)
	add_child(timer)

func _spawn_anky() -> void:
	var anky = ANKY.instantiate()
	var lado = randi() % 2
	var x = 30.0 if lado == 0 else get_viewport_rect().size.x - 30.0
	var y = get_viewport_rect().size.y * randf_range(0.3, 0.8)
	get_tree().current_scene.add_child(anky)
	anky.configurar(Vector2(x, y), 1 if lado == 0 else -1)

func _process(_delta: float) -> void:
	var clic_actual = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if clic_actual and not clic_anterior:
		var meteorito = METEORITO.instantiate()
		get_tree().current_scene.add_child(meteorito)
		meteorito.inicializar(get_global_mouse_position())
	clic_anterior = clic_actual
