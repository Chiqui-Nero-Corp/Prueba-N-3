extends Node2D

const ANKY = preload("res://anky.tscn")
const REXY = preload("res://rexy.tscn")
const VELO = preload("res://velo.tscn")
const ESTE = preload("res://este.tscn")
const METEORITO = preload("res://meteorito.tscn")
const METE_VOY = preload("res://RECORRER.mp3")

@export var volumen_recorrido_db: float = -14.0
@export var puntos_golpe_base: float = 1.0
@export var puntos_muerte_base: int = 25
@export var factor_ralentizacion_dinos: float = 0.25
@export var bonus_puntos_acierto: int = 1000

# --- REGLAS DE VICTORIA, DERROTA Y MENÚ ---
@export var objetivo_dinos: int = 150
@export var tiempo_limite_partida: float = 180.0
@export var max_errores_quiz: int = 3
@export_file("*.tscn") var ruta_menu: String = "res://hud.tscn"

var clic_anterior: bool = false
var dano_total: float = 0.0
var puntaje: int = 0
var dinos_eliminados: int = 0
var errores_quiz: int = 0
var ronda_preguntas_activa: bool = false
var partida_terminada: bool = false

var _label_hud_respaldo: Label = null
var _label_tiempo_partida: Label = null
var _label_victoria: Label = null
var _timer_partida: Timer = null

func _ready() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	ronda_preguntas_activa = false
	partida_terminada = false
	add_to_group("gestor_partida")

	_crear_hud_respaldo()
	_conectar_senales_quiz_existentes()

	if not get_tree().node_added.is_connected(_al_agregar_nodo):
		get_tree().node_added.connect(_al_agregar_nodo)

	var timer: Timer = Timer.new()
	timer.wait_time = 3.0
	timer.autostart = true
	timer.timeout.connect(_spawn_anky)
	add_child(timer)

	var tempo: Timer = Timer.new()
	tempo.wait_time = 2.0
	tempo.autostart = true
	tempo.timeout.connect(_spawn_rexy)
	add_child(tempo)

	var time: Timer = Timer.new()
	time.wait_time = 1.0
	time.autostart = true
	time.timeout.connect(_spawn_velo)
	add_child(time)

	_timer_partida = Timer.new()
	_timer_partida.wait_time = tiempo_limite_partida
	_timer_partida.one_shot = true
	_timer_partida.autostart = true
	_timer_partida.timeout.connect(_verificar_objetivo_dinos)
	add_child(_timer_partida)

	_actualizar_hud()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(ruta_menu)

func _contenedor_escena() -> Node:
	if get_tree() != null and get_tree().current_scene != null:
		return get_tree().current_scene
	return self

func _crear_hud_respaldo() -> void:
	var capa: CanvasLayer = CanvasLayer.new()
	capa.name = "CapaHUDRespaldo"
	capa.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(capa)

	_label_hud_respaldo = Label.new()
	_label_hud_respaldo.name = "HUDPuntajeKillsRespaldo"
	_label_hud_respaldo.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label_hud_respaldo.position = Vector2(-380, 20)
	_label_hud_respaldo.visible = false
	capa.add_child(_label_hud_respaldo)

	_label_tiempo_partida = Label.new()
	_label_tiempo_partida.name = "HUDTiempoRestante"
	_label_tiempo_partida.position = Vector2(20, 20)
	_label_tiempo_partida.add_theme_font_size_override("font_size", 24)
	capa.add_child(_label_tiempo_partida)

	_label_victoria = Label.new()
	_label_victoria.name = "CartelVictoria"
	_label_victoria.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label_victoria.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_victoria.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_victoria.add_theme_font_size_override("font_size", 42)
	_label_victoria.add_theme_color_override("font_color", Color.GOLD)
	_label_victoria.add_theme_color_override("font_outline_color", Color.BLACK)
	_label_victoria.add_theme_constant_override("outline_size", 8)
	_label_victoria.visible = false
	capa.add_child(_label_victoria)

func _conectar_si_es_quiz(nodo: Node) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	if nodo.has_signal("pregunta_activa_cambiada"):
		if not nodo.pregunta_activa_cambiada.is_connected(set_ronda_preguntas_activa):
			nodo.pregunta_activa_cambiada.connect(set_ronda_preguntas_activa)

func _conectar_senales_quiz_existentes() -> void:
	var raiz: Node = get_tree().root if get_tree() != null else _contenedor_escena()
	_conectar_si_es_quiz(raiz)
	for nodo: Node in raiz.find_children("*", "", true, false):
		_conectar_si_es_quiz(nodo)

func _al_agregar_nodo(nodo: Node) -> void:
	if nodo == null or not is_instance_valid(nodo):
		return
	_conectar_si_es_quiz(nodo)
	if nodo.is_in_group("dinos") and nodo.has_method("set_ralentizado"):
		nodo.set_ralentizado(ronda_preguntas_activa, _multiplicador_actual())

func _multiplicador_actual() -> float:
	if ronda_preguntas_activa and factor_ralentizacion_dinos > 0.0:
		return factor_ralentizacion_dinos
	return 1.0

func set_ronda_preguntas_activa(activa: bool) -> void:
	ronda_preguntas_activa = bool(activa)
	Engine.time_scale = 1.0
	var mult: float = _multiplicador_actual()
	for dino: Node in get_tree().get_nodes_in_group("dinos"):
		if dino != null and is_instance_valid(dino) and dino.has_method("set_ralentizado"):
			dino.set_ralentizado(ronda_preguntas_activa, mult)

func aplicar_buff_pregunta_correcta(_tipo_buff: String = "puntos") -> void:
	errores_quiz = 0
	puntaje += max(0, bonus_puntos_acierto)
	_actualizar_hud()

func registrar_respuesta_incorrecta() -> void:
	if partida_terminada:
		return
	errores_quiz += 1
	_actualizar_hud()
	if errores_quiz >= max_errores_quiz:
		_perder_partida("Fallaste 3 preguntas")

func _verificar_objetivo_dinos() -> void:
	if partida_terminada:
		return
	if dinos_eliminados < objetivo_dinos:
		_perder_partida("No llegaste a eliminar los dinos necesarios")

func _ganar_partida() -> void:
	if partida_terminada:
		return
	partida_terminada = true
	
	if _timer_partida != null:
		_timer_partida.stop()

	if _label_victoria != null:
		_label_victoria.text = "¡VICTORIA!\nEliminaste %d dinos\nPuntaje final: %d\n\nVolviendo al menú en 5 segundos..." % [dinos_eliminados, puntaje]
		_label_victoria.visible = true

	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file(ruta_menu)

func _perder_partida(motivo: String) -> void:
	if partida_terminada:
		return
	partida_terminada = true
	print("DERROTA: ", motivo)
	get_tree().quit()

func registrar_accion_combate(dano: float, golpe: float, muerte: int = 0) -> void:
	if partida_terminada:
		return
	var dano_valido: float = max(0.0, dano)
	var golpe_valido: float = puntos_golpe_base if golpe <= 0.0 else golpe
	var muerte_valida: int = max(0, muerte)
	dano_total += dano_valido
	var puntos_accion: int = int(round((dano_valido * golpe_valido) + float(muerte_valida)))
	puntaje += puntos_accion
	if muerte_valida > 0:
		dinos_eliminados += 1
	_actualizar_hud()
	
	if dinos_eliminados >= objetivo_dinos:
		_ganar_partida()

func sumar_baja(puntos: int = -1, dano: float = 0.0, golpe: float = 0.0) -> void:
	var bono_muerte: int = puntos_muerte_base if puntos < 0 else max(0, puntos)
	registrar_accion_combate(dano, golpe, bono_muerte)

func sumar_puntaje(cantidad: int) -> void:
	puntaje += max(0, cantidad)
	_actualizar_hud()

func _buscar_label_hud() -> Label:
	var raiz: Node = _contenedor_escena()
	var directo: Node = raiz.find_child("ObjetivoKills", true, false)
	if directo != null and directo is Label:
		return directo as Label
	for nodo: Node in raiz.find_children("*", "Label", true, false):
		if nodo == _label_hud_respaldo or nodo == _label_tiempo_partida or nodo == _label_victoria or not (nodo is Label):
			continue
		var nombre_minus: String = String(nodo.name).to_lower()
		if "puntaje" in nombre_minus or "kills" in nombre_minus or "dinos" in nombre_minus or "objetivo" in nombre_minus:
			return nodo as Label
	return null

func _actualizar_hud() -> void:
	var texto_base: String = "Puntaje: %d | Dinos: %d/%d | Errores: %d/%d" % [puntaje, dinos_eliminados, objetivo_dinos, errores_quiz, max_errores_quiz]
	var lbl_objetivo_kills: Label = _buscar_label_hud()
	if lbl_objetivo_kills != null:
		lbl_objetivo_kills.text = texto_base
		if _label_hud_respaldo != null:
			_label_hud_respaldo.visible = false
	elif _label_hud_respaldo != null:
		_label_hud_respaldo.text = texto_base
		_label_hud_respaldo.visible = true

func _reproducir_sonido_meteorito() -> void:
	if METE_VOY == null:
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = METE_VOY
	player.volume_db = volumen_recorrido_db
	player.pitch_scale = randf_range(0.95, 1.05)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _spawn_anky() -> void:
	var dino: Node = ANKY.instantiate()
	var lado: int = randi() % 2
	var x: float = 10.0 if lado == 0 else get_viewport_rect().size.x - 30.0
	var y: float = get_viewport_rect().size.y * randf_range(0.5, 0.8)
	var dir: int = 1 if lado == 0 else -1
	_contenedor_escena().add_child(dino)
	if dino.has_method("configurar"):
		dino.configurar(Vector2(x, y), dir)
	if dino.has_method("set_ralentizado"):
		dino.set_ralentizado(ronda_preguntas_activa, _multiplicador_actual())

func _spawn_rexy() -> void:
	var dino: Node = REXY.instantiate()
	var lado: int = randi() % 2
	var x: float = 10.0 if lado == 0 else get_viewport_rect().size.x - 30.0
	var y: float = get_viewport_rect().size.y * randf_range(0.5, 0.8)
	var dir: int = 1 if lado == 0 else -1
	_contenedor_escena().add_child(dino)
	if dino.has_method("configurar"):
		dino.configurar(Vector2(x, y), dir)
	if dino.has_method("set_ralentizado"):
		dino.set_ralentizado(ronda_preguntas_activa, _multiplicador_actual())

func _spawn_velo() -> void:
	var dino: Node = VELO.instantiate()
	var lado: int = randi() % 2
	var x: float = 10.0 if lado == 0 else get_viewport_rect().size.x - 30.0
	var y: float = get_viewport_rect().size.y * randf_range(0.5, 0.8)
	var dir: int = 1 if lado == 0 else -1
	_contenedor_escena().add_child(dino)
	if dino.has_method("configurar"):
		dino.configurar(Vector2(x, y), dir)
	if dino.has_method("set_ralentizado"):
		dino.set_ralentizado(ronda_preguntas_activa, _multiplicador_actual())

func _process(_delta: float) -> void:
	if _timer_partida != null and not _timer_partida.is_stopped() and _label_tiempo_partida != null:
		var segundos_restantes: int = int(ceil(_timer_partida.time_left))
		_label_tiempo_partida.text = "Tiempo restante: %d s" % segundos_restantes

	var clic_actual: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if clic_actual and not clic_anterior:
		var meteorito: Node = METEORITO.instantiate()
		_contenedor_escena().add_child(meteorito)
		meteorito.inicializar(get_global_mouse_position())
		_reproducir_sonido_meteorito()
	clic_anterior = clic_actual
