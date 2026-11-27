extends Control

signal pregunta_activa_cambiada(activa: bool)

@onready var label_tiempo: Label = $LabelTiempo
@onready var label_pregunta: Label = $LabelPregunta
@onready var contenedor_botones: VBoxContainer = $VBoxContainer
@onready var timer: Timer = $TimerPregunta
@onready var botones: Array[Button] = [
	$VBoxContainer/Boton0,
	$VBoxContainer/Boton1,
	$VBoxContainer/Boton2
]

# Tiempos y buff configurables
@export var tiempo_para_responder: float = 15.0
@export var tiempo_espera_siguiente: float = 30.0
@export var tipo_buff_por_acierto: String = "mixto"
@export var aumento_aceleracion_acierto: float = 600.0
@export var reduccion_aceleracion_fallo: float = 400.0

enum Estado { RESPONDIENDO, ESPERANDO }
var estado_actual: Estado = Estado.RESPONDIENDO
var mensaje_resultado: String = ""

var _fondo_oscuro: ColorRect

# Banco de 16 preguntas exclusivas de Caída Libre y Tiro Vertical
var banco_preguntas: Array[Dictionary] = [
	{
		"categoria": "Caída Libre",
		"pregunta": "Se lanza una piedra verticalmente hacia abajo desde un acantilado a 10 m/s y tarda 3 s en llegar al fondo. ¿Qué altura tiene el acantilado? (g = 10 m/s²)",
		"opciones": ["45 m", "75 m", "90 m"],
		"correcta": 1
	},
	{
		"categoria": "Caída Libre",
		"pregunta": "En la Luna (g ≈ 1.6 m/s²), un astronauta deja caer un martillo desde 3.2 m de altura. ¿Cuánto tiempo tarda en tocar el suelo?",
		"opciones": ["2 s", "4 s", "1.4 s"],
		"correcta": 0
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "Un proyectil se lanza hacia arriba y alcanza una altura máxima de 80 m. ¿Con qué velocidad inicial fue lanzado? (g = 10 m/s²)",
		"opciones": ["20 m/s", "40 m/s", "80 m/s"],
		"correcta": 1
	},
	{
		"categoria": "Caída Libre",
		"pregunta": "Un cuerpo cae libremente desde el reposo. ¿Qué distancia recorre únicamente durante el tercer segundo de su caída? (g = 10 m/s²)",
		"opciones": ["25 m", "45 m", "15 m"],
		"correcta": 0
	},
	{
		"categoria": "Caída Libre",
		"pregunta": "Se suelta un objeto desde 125 m de altura. ¿Cuánto tiempo tarda en recorrer los últimos 80 m antes de chocar? (g = 10 m/s²)",
		"opciones": ["2 s", "3 s", "4 s"],
		"correcta": 0
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "Desde un globo que sube a velocidad constante de 15 m/s se suelta un paquete cuando está a 50 m del suelo. ¿Con qué velocidad impacta el piso? (g = 10 m/s²)",
		"opciones": ["25 m/s", "35 m/s", "45 m/s"],
		"correcta": 1
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "Dos pelotas se lanzan simultáneamente: A se deja caer desde 60 m y B se lanza hacia arriba desde el suelo a 30 m/s. ¿En qué segundo se cruzan? (g = 10 m/s²)",
		"opciones": ["1 s", "2 s", "3 s"],
		"correcta": 1
	},
	{
		"categoria": "Caída Libre",
		"pregunta": "Si la velocidad de un objeto en caída libre se triplica respecto a un punto anterior, ¿cuántas veces mayor es la distancia que ha caído desde el reposo?",
		"opciones": ["3 veces", "6 veces", "9 veces"],
		"correcta": 2
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "Se lanza una pelota verticalmente hacia arriba a 30 m/s. ¿Cuánto tiempo tarda en regresar exactamente al punto de lanzamiento? (g = 10 m/s²)",
		"opciones": ["3 s", "6 s", "9 s"],
		"correcta": 1
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "En el punto más alto de un tiro vertical hacia arriba, ¿cuáles son los valores de su velocidad y su aceleración? (g = 10 m/s²)",
		"opciones": ["v = 0 y a = 0", "v = 0 y a = 10 m/s² abajo", "v = 10 m/s y a = 0"],
		"correcta": 1
	},
	{
		"categoria": "Caída Libre",
		"pregunta": "Se deja caer una moneda desde un puente y tarda 4 s en tocar el agua. ¿Con qué velocidad impacta la superficie? (g = 10 m/s²)",
		"opciones": ["20 m/s", "40 m/s", "80 m/s"],
		"correcta": 1
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "Un cohete de juguete se lanza hacia arriba a 50 m/s. ¿Qué altura alcanza al cabo de 2 segundos? (g = 10 m/s²)",
		"opciones": ["60 m", "80 m", "100 m"],
		"correcta": 1
	},
	{
		"categoria": "Caída Libre",
		"pregunta": "Dos esferas, una de 1 kg y otra de 10 kg, se sueltan al mismo tiempo desde 20 m en el vacío. ¿Cuál llega primero al suelo?",
		"opciones": ["La de 10 kg", "La de 1 kg", "Llegan al mismo tiempo"],
		"correcta": 2
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "Se lanza una piedra hacia arriba con rapidez de 25 m/s. ¿Cuál será su velocidad y dirección al pasar 4 segundos? (g = 10 m/s²)",
		"opciones": ["15 m/s hacia abajo", "15 m/s hacia arriba", "65 m/s hacia abajo"],
		"correcta": 0
	},
	{
		"categoria": "Caída Libre",
		"pregunta": "Un objeto se lanza hacia abajo con velocidad inicial de 15 m/s y alcanza 45 m/s antes de chocar. ¿Cuánto tiempo duró su caída? (g = 10 m/s²)",
		"opciones": ["2 s", "3 s", "4.5 s"],
		"correcta": 1
	},
	{
		"categoria": "Tiro Vertical",
		"pregunta": "Para que un objeto lanzado verticalmente alcance el doble de altura máxima, ¿por cuánto debe multiplicarse su velocidad inicial?",
		"opciones": ["Por 2", "Por √2", "Por 4"],
		"correcta": 1
	}
]

var preguntas_disponibles: Array[Dictionary] = []
var pregunta_actual: Dictionary
var puntos: int = 0
var numero_pregunta: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_preparar_fondo_oscuro()

	for i in range(botones.size()):
		botones[i].pressed.connect(_al_presionar_opcion.bind(i))

	timer.one_shot = true
	timer.timeout.connect(_al_terminar_timer)
	iniciar_quiz()

func _preparar_fondo_oscuro() -> void:
	_fondo_oscuro = ColorRect.new()
	_fondo_oscuro.color = Color(0.0, 0.0, 0.0, 0.45)
	_fondo_oscuro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fondo_oscuro.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo_oscuro.visible = false
	add_child(_fondo_oscuro)
	move_child(_fondo_oscuro, 0)

func _recargar_preguntas() -> void:
	preguntas_disponibles = banco_preguntas.duplicate()
	preguntas_disponibles.shuffle()

func iniciar_quiz() -> void:
	puntos = 0
	numero_pregunta = 0
	var gestor := get_tree().get_first_node_in_group("gestor_partida")
	if gestor != null:
		gestor.set_meta("bono_aceleracion_meteorito", 0.0)
	_recargar_preguntas()
	mostrar_siguiente_pregunta()

func mostrar_siguiente_pregunta() -> void:
	if preguntas_disponibles.is_empty():
		_recargar_preguntas()

	estado_actual = Estado.RESPONDIENDO
	pregunta_actual = preguntas_disponibles.pop_back()
	numero_pregunta += 1

	if _fondo_oscuro != null:
		_fondo_oscuro.visible = true
	label_pregunta.visible = true
	contenedor_botones.visible = true
	pregunta_activa_cambiada.emit(true)

	label_pregunta.text = "Pregunta %d [%s]\n%s" % [
		numero_pregunta,
		pregunta_actual["categoria"],
		pregunta_actual["pregunta"]
	]

	for i in range(botones.size()):
		botones[i].text = pregunta_actual["opciones"][i]
		botones[i].disabled = false

	timer.start(tiempo_para_responder)

func pasar_a_espera(resultado: String) -> void:
	estado_actual = Estado.ESPERANDO
	mensaje_resultado = resultado

	if _fondo_oscuro != null:
		_fondo_oscuro.visible = false
	label_pregunta.visible = false
	contenedor_botones.visible = false
	pregunta_activa_cambiada.emit(false)

	timer.start(tiempo_espera_siguiente)

func _process(_delta: float) -> void:
	if not timer.is_stopped():
		var segundos = int(ceil(timer.time_left))
		if estado_actual == Estado.RESPONDIENDO:
			label_tiempo.text = "Tiempo para responder: %d s" % segundos
		else:
			label_tiempo.text = "%s (Aciertos: %d)\nSiguiente pregunta en: %d s" % [mensaje_resultado, puntos, segundos]

func _actualizar_aceleracion_meteorito(cambio: float) -> void:
	var gestor := get_tree().get_first_node_in_group("gestor_partida")
	if gestor != null:
		var bono_actual: float = gestor.get_meta("bono_aceleracion_meteorito", 0.0)
		bono_actual = max(-2400.0, bono_actual + cambio)
		gestor.set_meta("bono_aceleracion_meteorito", bono_actual)

func _al_presionar_opcion(indice_elegido: int) -> void:
	if estado_actual != Estado.RESPONDIENDO:
		return

	if indice_elegido == pregunta_actual["correcta"]:
		puntos += 1
		get_tree().call_group("gestor_partida", "aplicar_buff_pregunta_correcta", tipo_buff_por_acierto)
		_actualizar_aceleracion_meteorito(aumento_aceleracion_acierto)
		pasar_a_espera("✅🗣️ ¡Genio!")
	else:
		get_tree().call_group("gestor_partida", "registrar_respuesta_incorrecta")
		_actualizar_aceleracion_meteorito(-reduccion_aceleracion_fallo)
		pasar_a_espera("❌ MAL HECHO nub")

func _al_terminar_timer() -> void:
	if estado_actual == Estado.RESPONDIENDO:
		get_tree().call_group("gestor_partida", "registrar_respuesta_incorrecta")
		_actualizar_aceleracion_meteorito(-reduccion_aceleracion_fallo)
		pasar_a_espera("⏰ SE TE ACABO EL TIEMPO nub")
	else:
		mostrar_siguiente_pregunta()
