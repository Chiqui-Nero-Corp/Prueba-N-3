extends RigidBody2D

# La cantidad de fuerza que se agregará en cada pulsación
@export var potencia_extra: float = 200.0

func _process(delta: float) -> void:
	# Detecta si el jugador presiona la tecla "Espacio" o hace clic
	if Input.is_action_just_pressed("ui_accept"):
		agregar_potencia_caida()

func agregar_potencia_caida() -> void:
	# Creamos un vector que apunta hacia abajo (0 en X, 1 en Y)
	# Y lo multiplicamos por la potencia que queremos aplicar
	var fuerza = Vector2(0, potencia_extra)
	
	# Aplicamos un impulso instantáneo hacia abajo
	apply_central_impulse(fuerza)
	
	print("¡Impulso aplicado! Velocidad actual: ", linear_velocity.y)
