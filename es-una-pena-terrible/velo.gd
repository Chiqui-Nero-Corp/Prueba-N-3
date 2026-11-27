extends Area2D

@export var velocidad: float = 500.0
@export var vida: float = 1.0
@export var valor_golpe: float = 10.0
@export var puntos_muerte: int = 10
@export var sprite_mira_izquierda: bool = false

var direccion: int = 1
var _multiplicador_velocidad: float = 1.0
var _ya_murio: bool = false

func _ready() -> void:
	add_to_group("dinos")
	_aplicar_orientacion()

func configurar(pos_inicial: Vector2, dir: int) -> void:
	global_position = pos_inicial
	direccion = -1 if dir < 0 else 1
	_aplicar_orientacion()

func _aplicar_orientacion() -> void:
	var va_izquierda: bool = direccion < 0
	var flip: bool = va_izquierda if not sprite_mira_izquierda else not va_izquierda
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = flip
	elif has_node("Sprite2D"):
		$Sprite2D.flip_h = flip

func set_ralentizado(activa: bool, multiplicador: float) -> void:
	if activa and multiplicador > 0.0:
		_multiplicador_velocidad = multiplicador
	else:
		_multiplicador_velocidad = 1.0

func recibir_daño(cantidad: float) -> void:
	if _ya_murio:
		return
	var dano_aplicado: float = max(0.0, cantidad)
	vida -= dano_aplicado
	var murio_ahora: bool = vida <= 0.0
	if murio_ahora:
		_ya_murio = true
	var bono_kill: int = puntos_muerte if murio_ahora else 0
	get_tree().call_group("gestor_partida", "registrar_accion_combate", dano_aplicado, valor_golpe, bono_kill)
	if murio_ahora:
		queue_free()

func _process(delta: float) -> void:
	global_position.x += velocidad * float(direccion) * _multiplicador_velocidad * delta
