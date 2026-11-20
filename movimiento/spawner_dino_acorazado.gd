extends Node2D

# 1. Cargamos la escena guardada de tu NPC (Asegurate de poner la ruta correcta de tu archivo .tscn)


@onready var npc_escena3 = preload("res://dino_acorazado.tscn")
# 2. Referencia automática al nodo Timer que creamos como hijo
@onready var timer = $Timer_dino_acorazado

# Margen para que no aparezcan justo encima del borde exacto de la pantalla
var margen_spawn = 50.0

func _ready():
	# Conectamos la señal del Timer al código
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	_generar_npc()

func _generar_npc():
	# Creamos una nueva copia física (instancia) del NPC en memoria
	
	var nuevo_npc3 = npc_escena3.instantiate()
	# Obtenemos las dimensiones totales de la pantalla actual
	var limite_pantalla = get_viewport_rect().size
	
	# Calculamos posiciones aleatorias seguras dentro de la pantalla

	var x_aleatoria3 = randf_range(margen_spawn, limite_pantalla.x - margen_spawn)
	var y_aleatoria3 = randf_range(margen_spawn, limite_pantalla.y - margen_spawn)
	# Asignamos la posición combinada aleatoria al NPC
	nuevo_npc3.position = Vector2(x_aleatoria3, y_aleatoria3)
	# Añadimos el NPC oficialmente a la escena del juego
	
	add_child(nuevo_npc3)
