class_name SettingSelectionScreen
extends Screen

const NB_COLS := 2
const NB_ROWS := 2
const BUTTON_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_selector.tscn")

@onready var background_node: TextureRect = %Background

# REFERENCIAS A LOS NODOS AREA2D
@onready var selectable_area_nodes: Array[Area2D] = [
	%BotonBracketFlagArea2D, # Índice 0 (PLAY)
	%BotonBracketFlag2Area2D, # Índice 1 (CONTROLS)
	%BotonBracketFlag3Area2D, # Índice 2 (ABOUT)
	%BotonBracketFlag4Area2D # Índice 3 (MENU/BACK)
]

var options: Array[String] = ["PLAY", "CONTROLS", "ABOUT", "MENU"] # Opciones

var selection: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
var selectors: Array[FlagSelector] = []

var move_dirs: Dictionary[KeyUtils.Action, Vector2i] = {
	KeyUtils.Action.UP: Vector2i.UP,
	KeyUtils.Action.DOWN: Vector2i.DOWN,
	KeyUtils.Action.LEFT: Vector2i.LEFT,
	KeyUtils.Action.RIGHT: Vector2i.RIGHT
}

func _ready() -> void:
	setup_bracketflags()
	connect_input_events()
	place_selectors()
	update_labels()

func _process(_delta: float) -> void:
	for i in range(selectors.size()):
		var scheme: Player.ControlScheme = selectors[i].control_scheme

		# Navegación (Teclado/Mando)
		for action in move_dirs.keys():
			if KeyUtils.is_action_just_pressed(scheme, action):
				try_navigate(i, move_dirs[action])

		# Confirmar con SHOOT (Teclado/Mando)
		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.SHOOT):
			SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
			var index: int = selection[i].x + selection[i].y * NB_COLS
			handle_selection(index)

		# Retroceder con PASS (Teclado/Mando)
		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.PASS):
			SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)

# ----------------------------------------------------------------------
# 🎯 FUNCIONES DE POSICIÓN Y CURSOR
# ----------------------------------------------------------------------

func get_visual_node_position(index: int) -> Vector2:
	if index >= selectable_area_nodes.size():
		return Vector2.ZERO
		
	var area_node = selectable_area_nodes[index]
	var visual_node: Node = area_node.get_child(0) if area_node.get_child_count() > 0 else null
	
	var base_position: Vector2 = area_node.global_position
	if visual_node:
		base_position = visual_node.global_position
		
	return base_position

func get_cursor_position(index: int) -> Vector2:
	if index >= selectable_area_nodes.size():
		return Vector2.ZERO

	var area_node = selectable_area_nodes[index]
	if not is_instance_valid(area_node):
		return Vector2.ZERO

	var visual_node: Control = null
	if area_node.get_child_count() > 0:
		for c in area_node.get_children():
			if c is Control:
				visual_node = c # BotonBracketFlag (Control)
				break

	var base_pos: Vector2 = area_node.global_position
	if visual_node:
		# 💡 CORRECCIÓN CLAVE: Usar la posición global de la esquina superior izquierda.
		base_pos = visual_node.global_position 
	else:
		# Si no hay nodo visual, usamos la posición del Area2D
		base_pos = area_node.global_position

	# TRANSFORMAR LA POSICIÓN AL SISTEMA DE COORDENADAS DEL NODO PADRE (Background)
	if is_instance_valid(background_node):
		base_pos = background_node.get_global_transform_with_canvas().affine_inverse() * base_pos

	# AJUSTE: Si el selector (el marco amarillo) es más grande que el botón, 
	# puedes necesitar ajustes adicionales (ej. si el "1P" es parte del selector)
	
	# 🗑️ Borra esta línea si ya no es necesaria: base_pos.y -= 6.0
	# Si tu selector (el marco amarillo) es del mismo tamaño que el botón, ¡esto debería funcionar!

	return base_pos

# ----------------------------------------------------------------------
# 🎯 LÓGICA DE CONEXIÓN Y MANEJO DE TOQUE/HOVER
# ----------------------------------------------------------------------

func connect_input_events() -> void:
	for i in range(selectable_area_nodes.size()):
		var area_node: Area2D = selectable_area_nodes[i]
		
		area_node.input_pickable = true
		
		# Conexión de TOQUE/CLIC
		area_node.input_event.connect(func(_viewport, event, _shape_idx):
			on_area_input(i, _viewport, event, _shape_idx)
		)
		
		# Conexión de HOVER (Ratón en PC)
		area_node.mouse_entered.connect(func(): on_mouse_enter_area(i))
		area_node.mouse_exited.connect(func(): on_mouse_exit_area(i))

# --- Manejadores de Input ---
func on_area_input(index: int, _viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed(KeyUtils.ACTIONS_MAP[Player.ControlScheme.P1][KeyUtils.Action.SHOOT]) and not event.is_echo():
		if event.is_pressed(): 
			SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
			selection[0] = index_to_coords(index)
			selectors[0].position = get_cursor_position(index)
			handle_selection(index)
			get_viewport().set_input_as_handled()

func on_mouse_enter_area(index: int) -> void:
	if selectors.size() > 0:
		selection[0] = index_to_coords(index)
		selectors[0].position = get_cursor_position(index)

		# 🔊 Sonido de navegación opcional
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

func on_mouse_exit_area(_index: int) -> void:
	pass

# ----------------------------------------------------------------------
# 🔹 LÓGICA DE NAVEGACIÓN Y MENÚ 
# ----------------------------------------------------------------------

func setup_bracketflags() -> void:
	for i in range(selectable_area_nodes.size()):
		var area_node := selectable_area_nodes[i] 
		
		if area_node.get_child_count() > 0:
			var node = area_node.get_child(0) 
			if node.has_node("Label"):
				node.get_node("Label").text = options[i]

func place_selectors() -> void:
	add_selector(Player.ControlScheme.P1)
	if not GameManager.player_setup[1].is_empty():
		add_selector(Player.ControlScheme.P2)

func add_selector(control_scheme: Player.ControlScheme) -> void:
	var selector: FlagSelector = BUTTON_SELECTOR_PREFAB.instantiate()
	selector.control_scheme = control_scheme
	selectors.append(selector)
	
	if is_instance_valid(background_node):
		background_node.add_child(selector)
		selector.z_index = 100  # 🔝 Asegura que quede encima de los botones
	else:
		print("ERROR: Background node is null. Cannot add selector.")
		return
		
	selector.position = get_cursor_position(0) 
	if control_scheme == Player.ControlScheme.P2:
		pass

func try_navigate(index: int, direction: Vector2i) -> void:
	# Define el rectángulo de la cuadrícula
	var rect := Rect2i(0, 0, NB_COLS, NB_ROWS)
	
	var new_selection: Vector2i = selection[index] + direction

	# Solo navega si el nuevo punto está dentro de los límites
	if rect.has_point(new_selection):
		selection[index] = new_selection
		
		# Cálculo correcto del índice: x + y * NB_COLS
		var idx: int = selection[index].x + selection[index].y * NB_COLS
		
		selectors[index].position = get_cursor_position(idx)
		
		if selectors[index].control_scheme == Player.ControlScheme.P2:
			selectors[index].position += Vector2(0, 0) # Mantienes esto, aunque no hace nada
			
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		update_labels()

func update_labels() -> void:
	# Calcula el índice del elemento actualmente seleccionado por el Jugador 1
	var selected_index_p1: int = selection[0].x + selection[0].y * NB_COLS 
	
	for i in range(selectable_area_nodes.size()):
		var area_node := selectable_area_nodes[i]
		
		if area_node.get_child_count() > 0:
			var node = area_node.get_child(0)
			if node is BotonBracketFlag:
				# Compara el índice del botón (i) con el índice seleccionado
				if i == selected_index_p1: 
					# Asegúrate de que tu componente BotonBracketFlag tenga un método set_text
					node.set_text("* " + options[i])
					node.set_highlighted(true)
				else:
					node.set_text(options[i])
					node.set_highlighted(false)

func handle_selection(index: int) -> void:
	match index:
		0: # PLAY
			transition_screen(SoccerGame.ScreenType.GAME_MODE_SELECTION)
		1: # CONTROLS
			transition_screen(SoccerGame.ScreenType.CONTROLS)
		2: # ABOUT 
			transition_screen(SoccerGame.ScreenType.ABOUT) 
		3: # MENU/BACK
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)

func index_to_coords(index: int) -> Vector2i:
	# Coordenada X = resto de la división por NB_COLS (0 o 1)
	# Coordenada Y = resultado entero de la división por NB_COLS (0 o 1)
	return Vector2i(index % NB_COLS, index / NB_COLS)

# --- Funciones generadas por el editor (Manejadores de Area2D) ---

func _on_boton_bracket_flag_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	on_area_input(0, _viewport, event, _shape_idx)

func _on_boton_bracket_flag_2_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	on_area_input(1, _viewport, event, _shape_idx)

func _on_boton_bracket_flag_3_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	on_area_input(2, _viewport, event, _shape_idx)

func _on_boton_bracket_flag_4_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	on_area_input(3, _viewport, event, _shape_idx)
