class_name ControlsScreen
extends Screen

# --- PRECARGAS NECESARIAS ---
const BACK_ICON := preload("res://assets/art/ui/game_mode_selection/back_icon.png")
const BUTTON_SELECTOR_PREFAB := preload("res://scenes/screens/main_menu/button_selector.tscn")
const BOTON_BRACKET_FLAG_PREFAB := preload("res://scenes/screens/quiz/boton_bracket_flag.tscn")
# ------------------------------

# --- Mapeo de Acciones a Teclas Físicas (Para mostrar en la UI) ---
# **P1: Flechas / Ctrl Derecho / Shift Derecho**
const P1_KEY_MAP: Dictionary = {
	"p1_left": "◄",
	"p1_right": "►",
	"p1_up": "▲",
	"p1_down": "▼",
	"p1_shoot": "R.Ctrl",
	"p1_pass": "R.Shift",
}

# **P2: WASD / Espacio / Q**
const P2_KEY_MAP: Dictionary = {
	"p2_left": "A",
	"p2_right": "D",
	"p2_up": "W",
	"p2_down": "S",
	"p2_shoot": "Space",
	"p2_pass": "Q",
}

# --- Mapeo para acciones que no están en KeyUtils directamente ---
const OTHER_KEY_MAP: Dictionary = {
	"RUN": "Alt Izquierdo", # Asumiendo Alt es Sprint para P1
}
# -----------------------------------------------------------------

# --- CONTENEDORES DE LA NUEVA ESCENA ---
@onready var far_left_container: VBoxContainer = %FarLeftOptionsContainer
@onready var left_container: VBoxContainer = %LeftOptionsContainer2
@onready var right_container: VBoxContainer = %RightOptionsContainer2
@onready var far_right_container: VBoxContainer = %FarRightOptionsContainer3
@onready var back_button_container: VBoxContainer = %BackContainer

# 💡 REFERENCIA DEL BOTÓN DE REGRESO (SeleccionBotonesBracketFlag)
@onready var back_button_node: Control = %BackContainer.get_child(0) 
# ---------------------------------------

# Mapa simplificado de acciones para las 4 columnas (8 slots)
const CONTROL_SLOTS: Array = [
	# COLUMNA 1 (FAR LEFT)
	{"desc": "Move", "action": "ARROWS", "color": "#FFC000"}, # Slot 1 (arriba)
	{"desc": "Sprint", "action": "RUN", "color": "#00FF00"}, # Slot 2 (abajo)
	
	# COLUMNA 2 (LEFT)
	{"desc": "Charge Shot (Hold)", "action": "SHOOT", "color": "#FF8000"}, # Slot 3
	{"desc": "Shoot/Pass (Release)", "action": "SHOOT", "color": "#FF0000"}, # Slot 4

	# COLUMNA 3 (RIGHT)
	{"desc": "Ground Pass", "action": "PASS", "color": "#00AFFF"}, # Slot 5
	{"desc": "Tackle (Near)", "action": "SHOOT", "color": "#800080"}, # Slot 6

	# COLUMNA 4 (FAR RIGHT)
	{"desc": "Header (In Air)", "action": "SHOOT", "color": "#FFFF00"}, # Slot 7
	{"desc": "Volley Kick (Facing Goal)", "action": "SHOOT", "color": "#00FFC0"}, # Slot 8
]

var containers_map: Array[VBoxContainer] = []
var all_buttons: Array[BotonBracketFlag] = []
var selectors: Array[FlagSelector] = [] # Selector para el botón de regreso

func _ready() -> void:
	containers_map = [far_left_container, left_container, right_container, far_right_container]
	
	setup_control_buttons()
	setup_selectors()
	
	# 🎯 CONFIGURACIÓN DEL BOTÓN DE REGRESO PARA EL CLIC/TOQUE
	# 1. Asegúrate de que el nodo pueda recibir input
	back_button_node.mouse_filter = Control.MOUSE_FILTER_STOP 
	
	# 2. Conecta la señal de input GUI (clic/toque)
	back_button_node.gui_input.connect(_on_back_button_gui_input)


# Nueva función auxiliar para obtener la tecla
func get_key_for_action(action_name: String) -> String:
	match action_name:
		"ARROWS":
			# P1 (Flechas)
			var p1_up = P1_KEY_MAP.get("p1_up", "▲")
			var p1_down = P1_KEY_MAP.get("p1_down", "▼")
			var p1_left = P1_KEY_MAP.get("p1_left", "◄")
			var p1_right = P1_KEY_MAP.get("p1_right", "►")
			var p1_keys = "%s %s %s %s" % [p1_up, p1_down, p1_left, p1_right]
			
			# P2 (WASD)
			var p2_up = P2_KEY_MAP.get("p2_up", "W")
			var p2_down = P2_KEY_MAP.get("p2_down", "S")
			var p2_left = P2_KEY_MAP.get("p2_left", "A")
			var p2_right = P2_KEY_MAP.get("p2_right", "D")
			var p2_keys = "%s %s %s %s" % [p2_up, p2_down, p2_left, p2_right]
			
			# Formato: P1_Keys / P2_Keys (Debe ser multilínea en el Label)
			return "%s / %s" % [p1_keys, p2_keys]
			
		"RUN":
			# Asumo que P2 usa Z, X o similar para sprint. Aquí dejo solo P1 para RUN.
			return OTHER_KEY_MAP.get(action_name, "N/A")
		
		"SHOOT":
			# Obtenemos el nombre de la acción de Godot para P1 y P2
			var p1_action_name = KeyUtils.ACTIONS_MAP[Player.ControlScheme.P1][KeyUtils.Action.SHOOT]
			var p2_action_name = KeyUtils.ACTIONS_MAP[Player.ControlScheme.P2][KeyUtils.Action.SHOOT]
			
			var p1_key = P1_KEY_MAP.get(p1_action_name, "R.Ctrl")
			var p2_key = P2_KEY_MAP.get(p2_action_name, "Space")
			
			# Formato: P1_Key / P2_Key
			return "%s / %s" % [p1_key, p2_key]
			
		"PASS":
			# Obtenemos el nombre de la acción de Godot para P1 y P2
			var p1_action_name = KeyUtils.ACTIONS_MAP[Player.ControlScheme.P1][KeyUtils.Action.PASS]
			var p2_action_name = KeyUtils.ACTIONS_MAP[Player.ControlScheme.P2][KeyUtils.Action.PASS]
			
			var p1_key = P1_KEY_MAP.get(p1_action_name, "R.Shift")
			var p2_key = P2_KEY_MAP.get(p2_action_name, "Q")
			
			# Formato: P1_Key / P2_Key
			return "%s / %s" % [p1_key, p2_key]
			
		_:
			return "N/A" # Acción no mapeada

func setup_control_buttons() -> void:
	var slot_index = 0
	
	for container in containers_map:
		var button_nodes: Array[BotonBracketFlag] = []
		# Filtramos solo los nodos de botón
		for child in container.get_children():
			if child is BotonBracketFlag:
				button_nodes.append(child)

		for button_node in button_nodes:
			if slot_index < CONTROL_SLOTS.size():
				var slot = CONTROL_SLOTS[slot_index]
				
				var button: BotonBracketFlag = button_node
				
				# Muestra la tecla física (P1 / P2) en el texto PRINCIPAL
				var key_name = get_key_for_action(slot.action)
				button.set_text(key_name)
				
				# Muestra la descripción de la acción en el texto PEQUEÑO
				button.set_small_text(slot.desc)
				
				button.set_background_color(Color(slot.color))
				
				button.set_highlighted(false)
				button.set_icon(null)
				all_buttons.append(button)
				
				slot_index += 1
			else:
				break
	# Configuramos el botón BACK, que es el último nodo en back_button_container
	setup_back_button_display()


func setup_back_button_display() -> void:
	# back_button_node ya está referenciado
	
	# Configuramos el Botón de Regreso
	if back_button_node.has_method("set_text"):
		back_button_node.set_text("BACK")
	if back_button_node.has_method("set_small_text"):
		back_button_node.set_small_text("SETTINGS") # Indicamos a dónde regresa
	
	if back_button_node.has_method("set_icon"):
		back_button_node.set_icon(BACK_ICON)
	if back_button_node.has_method("set_background_color"):
		back_button_node.set_background_color(Color("#6A5ACD")) # Azul purpúreo


# --- 🔹 Nueva función para configurar los selectores de P1 y P2 ---
func setup_selectors() -> void:
	# back_button_node ya está referenciado

	# 1. Selector P1 (Siempre se agrega)
	add_selector_to_back_button(Player.ControlScheme.P1, back_button_node.position)
	
	# 2. Selector P2 (Solo si hay dos jugadores configurados)
	if GameManager.player_setup.size() > 1 and not GameManager.player_setup[1].is_empty():
		add_selector_to_back_button(Player.ControlScheme.P2, back_button_node.position)

func add_selector_to_back_button(control_scheme: Player.ControlScheme, position: Vector2) -> void:
	var selector: FlagSelector = BUTTON_SELECTOR_PREFAB.instantiate()
	
	# 1. Asignar esquema de control
	selector.control_scheme = control_scheme
	
	# 2. Llamar EXPLICITAMENTE a update_indicators() para forzar la visibilidad de P1/P2
	if selector.has_method("update_indicators"):
		selector.update_indicators()
		
	selectors.append(selector)
	back_button_container.add_child(selector)
	
	# 3. Posicionar el selector sobre el botón
	selector.position = position

# --- 🎯 MANEJADOR DE CLIC DEL RATÓN/TOQUE ---
func _on_back_button_gui_input(event: InputEvent) -> void:
	# Chequeamos si el evento es el clic izquierdo del ratón (que incluye toque de pantalla)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		# Ejecutar la acción de regreso
		handle_back_action()
		
		# Marcar el evento como manejado
		get_viewport().set_input_as_handled()

# --- 🎯 LÓGICA DE REGRESO ---
func handle_back_action() -> void:
	SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
	# Regresa a la pantalla de selección de opciones
	transition_screen(SoccerGame.ScreenType.OPTIONS_SELECTION)

# --- Control de Entrada Simplificado para solo el botón de regreso ---
func _process(_delta: float) -> void:
	# Obtenemos la posición del botón
	var back_button_pos = back_button_node.position
	
	var confirmed = false
	
	for i in range(selectors.size()):
		var selector = selectors[i]
		var scheme = selector.control_scheme
		
		# Navegación y Confirmación (solo hay 1 botón, así que solo confirmamos/cancelamos)
		# 💡 Aquí se maneja la entrada de teclado/mando
		if KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.SHOOT) or KeyUtils.is_action_just_pressed(scheme, KeyUtils.Action.PASS):
			confirmed = true
		
		# Aseguramos que el selector siga al botón (ya que el botón puede moverse)
		selector.position = back_button_pos
	
	if confirmed:
		# Lógica de confirmación por teclado/mando
		handle_back_action() 
		
func _input(_event: InputEvent) -> void:
	# El input de ratón/toque está manejado por la conexión gui_input del nodo Control
	pass
