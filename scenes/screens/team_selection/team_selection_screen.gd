class_name TeamSelectionScreen
extends Screen

const FLAG_ANCHOR_POINT := Vector2(35, 80)
const NB_COLS := 4
const NB_ROWS := 2
const FLAG_SELECTOR_PREFAB := preload("res://scenes/screens/team_selection/flag_selector.tscn")

@onready var flags_container: Control = %FlagsContainer

var selection: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO]
var selectors: Array[FlagSelector] = []

var move_dirs: Dictionary[KeyUtils.Action, Vector2i] = {
	KeyUtils.Action.UP: Vector2i.UP,
	KeyUtils.Action.DOWN: Vector2i.DOWN,
	KeyUtils.Action.LEFT: Vector2i.LEFT,
	KeyUtils.Action.RIGHT: Vector2i.RIGHT,
}

func _ready() -> void:
	place_flags()
	place_selectors()

func _process(_delta: float) -> void:
	# Recorremos los selectores para ver cuál debe moverse
	for i in range(selectors.size()):
		var selector = selectors[i]
		
		# Solo procesamos input si el selector NO ha confirmado selección todavía
		if not selector.is_selected:
			for action: KeyUtils.Action in move_dirs.keys():
				if KeyUtils.is_action_just_pressed(selector.control_scheme, action):
					try_navigate(i, move_dirs[action])
	
	# Cancelar / Volver atrás (Solo si nadie ha seleccionado nada aún)
	if selectors.size() > 0 and not selectors[0].is_selected and KeyUtils.is_action_just_pressed(Player.ControlScheme.P1, KeyUtils.Action.PASS):
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		transition_screen(SoccerGame.ScreenType.MAIN_MENU)

func try_navigate(selector_index: int, direction: Vector2i) -> void:
	var rect: Rect2i = Rect2i(0, 0, NB_COLS, NB_ROWS)
	if rect.has_point(selection[selector_index] + direction):
		selection[selector_index] += direction
		var flag_index := selection[selector_index].x + selection[selector_index].y * NB_COLS
		
		# Aseguramos que el array tenga tamaño suficiente antes de asignar
		if GameManager.player_setup.size() <= selector_index:
			GameManager.player_setup.resize(selector_index + 1)
			
		GameManager.player_setup[selector_index] = DataLoader.get_countries()[1 + flag_index]
		selectors[selector_index].position = flags_container.get_child(flag_index).position
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)

func place_flags() -> void:
	for j in range(NB_ROWS):
		for i in range(NB_COLS):
			var flag_texture := TextureRect.new()
			flag_texture.position = FLAG_ANCHOR_POINT + Vector2(55 * i, 50 * j)
			var country_index := 1 + i + NB_COLS * j
			var country := DataLoader.get_countries()[country_index]
			flag_texture.texture = FlagHelper.get_texture(country)
			flag_texture.scale = Vector2(2, 2)
			flag_texture.z_index = 1
			flags_container.add_child(flag_texture)

func place_selectors() -> void:
	# Inicialmente solo P1 (o P1 y P2 si es multijugador real)
	add_selector(Player.ControlScheme.P1)
	if GameManager.player_setup.size() > 1 and not GameManager.player_setup[1].is_empty():
		add_selector(Player.ControlScheme.P2)

func add_selector(control_scheme: Player.ControlScheme) -> void:
	var selector := FLAG_SELECTOR_PREFAB.instantiate()
	selector.position = flags_container.get_child(0).position
	selector.control_scheme = control_scheme
	selector.selected.connect(on_selector_selected.bind())
	selectors.append(selector)
	flags_container.add_child(selector)
	
	# Inicializar posición visual correcta
	var current_idx_in_array = selectors.size() - 1
	# Asegurar que el array de selección tenga el tamaño correcto
	if selection.size() <= current_idx_in_array:
		selection.resize(current_idx_in_array + 1)
		selection[current_idx_in_array] = Vector2i.ZERO
		
	var initial_index = selection[current_idx_in_array].x + selection[current_idx_in_array].y * NB_COLS
	selector.position = flags_container.get_child(initial_index).position

func on_selector_selected() -> void:
	var mode := screen_data.mode if screen_data != null else ""
	
	# 1. CUSTOM MATCH & QUIZ (1P Flow)
	if (mode == "custom_match" or mode == "animals_quiz" or mode == "soccer_quiz"):
		# Si solo hay 1 selector (el del P1) y acaba de confirmar...
		if selectors.size() == 1:
			# Desactivar visualmente el selector del P1 (quitar borde/animación si es necesario)
			# Nota: Tu prefab FlagSelector debería tener lógica para cambiar visualmente cuando is_selected es true.
			
			# Crear el selector del CPU para que el P1 elija el rival
			_create_cpu_selector_for_custom_match()
			return

	# 2. TOURNAMENT (1P)
	if mode == "tournament" and selectors.size() == 1:
		_handle_single_player_tournament_start()
		return

	# Validación General: Esperar a que TODOS los selectores estén listos
	for selector in selectors:
		if not selector.is_selected:
			return
			
	var country_p1 := GameManager.player_setup[0]
	var country_p2 := GameManager.player_setup[1]
	
	if country_p1 == country_p2:
		push_warning("⚠️ Debes seleccionar dos equipos distintos.")
		# Des-seleccionamos solo el último para que cambie
		selectors.back().is_selected = false
		selectors.back().update_indicators()
		return
		
	GameManager.current_match = Match.new(country_p2, country_p1)
	
	var is_p2_cpu_opponent = selectors.size() > 1 and selectors[1].is_cpu
	
	GameManager.is_p2_cpu = is_p2_cpu_opponent # Establece si el P2 es CPU
	
	match mode:
		"animals_quiz", "soccer_quiz":
			_start_quiz_mode(mode, is_p2_cpu_opponent)
		"custom_match":
			var custom_tournament := Tournament.new(true)
			custom_tournament.matches = {
				Tournament.Stage.FINALS: [Match.new(country_p1, country_p2)],
				Tournament.Stage.COMPLETE: []
			}
			screen_data.set_tournament(custom_tournament)
			transition_screen(SoccerGame.ScreenType.CUSTOM_MATCH, screen_data)
		"tournament":
			_handle_multiplayer_tournament_start(country_p1, country_p2)
		_:
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)

# --- HELPERS ---
func _start_quiz_mode(mode: String, is_cpu: bool = false) -> void:
	screen_data.set_meta("is_p2_dummy", is_cpu)
	if mode == "animals_quiz":
		transition_screen(SoccerGame.ScreenType.ANIMALS_QUIZ, screen_data)
	else:
		transition_screen(SoccerGame.ScreenType.SOCCER_QUIZ, screen_data)

func _create_cpu_selector_for_custom_match() -> void:
	var cpu_selector := FLAG_SELECTOR_PREFAB.instantiate()
	
	# Asignamos el mismo esquema de control que P1 para que P1 lo mueva
	cpu_selector.control_scheme = Player.ControlScheme.P1
	cpu_selector.is_cpu = true
	cpu_selector.is_selected = false # Empieza activo para moverse
	cpu_selector.update_indicators() # Asegura que se vea el borde
	
	flags_container.add_child(cpu_selector)
	selectors.append(cpu_selector)
	
	cpu_selector.selected.connect(on_selector_selected.bind())
	
	# Posición inicial (en la primera bandera disponible o la 0)
	cpu_selector.position = flags_container.get_child(0).position
	
	# Asegurar espacio en el array y valor por defecto
	if GameManager.player_setup.size() < 2:
		GameManager.player_setup.resize(2)
	
	# Inicializar selección del segundo selector
	if selection.size() < 2:
		selection.resize(2)
		selection[1] = Vector2i.ZERO # Reiniciar posición del cursor 2
		
	GameManager.player_setup[1] = DataLoader.get_countries()[1] 

func _handle_single_player_tournament_start() -> void:
	GameManager.is_p2_cpu = true
	var p1 = GameManager.player_setup[0]
	var safe_countries = _get_safe_country_list()
	if safe_countries.has(p1): safe_countries.erase(p1)
	safe_countries.shuffle()
	var tournament_countries: Array[String] = [p1]
	tournament_countries.append_array(safe_countries.slice(0, 7))
	while tournament_countries.size() < 8:
		tournament_countries.append(safe_countries[randi() % safe_countries.size()])
	_start_tournament(tournament_countries)

func _handle_multiplayer_tournament_start(p1: String, p2: String) -> void:
	GameManager.is_p2_cpu = false
	var safe_countries = _get_safe_country_list()
	if safe_countries.has(p1): safe_countries.erase(p1)
	if safe_countries.has(p2): safe_countries.erase(p2)
	safe_countries.shuffle()
	var get_rival = func() -> String:
		if safe_countries.size() > 0: return safe_countries.pop_front()
		var backup = _get_safe_country_list()
		return backup[randi() % backup.size()]
	var tournament_countries: Array[String] = []
	tournament_countries.append(p1)
	tournament_countries.append(get_rival.call())
	tournament_countries.append(get_rival.call())
	tournament_countries.append(get_rival.call())
	tournament_countries.append(p2)
	tournament_countries.append(get_rival.call())
	tournament_countries.append(get_rival.call())
	tournament_countries.append(get_rival.call())
	_start_tournament(tournament_countries)

func _get_safe_country_list() -> Array[String]:
	var raw_list = DataLoader.get_countries()
	var clean_list: Array[String] = []
	for c in raw_list:
		if c == null or c.strip_edges() == "" or c == "DEFAULT": continue
		if FlagHelper.get_texture(c) == null: continue
		clean_list.append(c)
	return clean_list

func _start_tournament(teams: Array[String]) -> void:
	var new_tournament := Tournament.new(false)
	new_tournament.matches.clear()
	new_tournament.create_bracket(Tournament.Stage.QUARTER_FINALS, teams)
	screen_data.set_tournament(new_tournament)
	transition_screen(SoccerGame.ScreenType.TOURNAMENT, screen_data)
