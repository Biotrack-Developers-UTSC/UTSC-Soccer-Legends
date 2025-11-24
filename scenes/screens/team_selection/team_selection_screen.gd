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
	for i in range(selectors.size()):
		var selector = selectors[i]
		if not selector.is_selected:
			for action: KeyUtils.Action in move_dirs.keys():
				if KeyUtils.is_action_just_pressed(selector.control_scheme, action):
					try_navigate(i, move_dirs[action])
	if not selectors[0].is_selected and KeyUtils.is_action_just_pressed(Player.ControlScheme.P1, KeyUtils.Action.PASS):
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		transition_screen(SoccerGame.ScreenType.MAIN_MENU)

# --- Navegación entre banderas ---
func try_navigate(selector_index: int, direction: Vector2i) -> void:
	var rect: Rect2i = Rect2i(0, 0, NB_COLS, NB_ROWS)
	if rect.has_point(selection[selector_index] + direction):
		selection[selector_index] += direction
		var flag_index := selection[selector_index].x + selection[selector_index].y * NB_COLS
		GameManager.player_setup[selector_index] = DataLoader.get_countries()[1 + flag_index]
		selectors[selector_index].position = flags_container.get_child(flag_index).position
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)

# --- Crea las banderas ---
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

# --- Crea los selectores ---
func place_selectors() -> void:
	add_selector(Player.ControlScheme.P1)

	# Solo agrega P2 si realmente hay dos jugadores activos
	if GameManager.player_setup.size() > 1 and not GameManager.player_setup[1].is_empty():
		add_selector(Player.ControlScheme.P2)

func add_selector(control_scheme: Player.ControlScheme) -> void:
	var selector := FLAG_SELECTOR_PREFAB.instantiate()
	selector.position = flags_container.get_child(0).position
	selector.control_scheme = control_scheme
	selector.selected.connect(on_selector_selected.bind())
	selectors.append(selector)
	flags_container.add_child(selector)
	print("✅ Selector agregado para:", control_scheme)
	
# --- Al seleccionar ---
func on_selector_selected() -> void:
	var mode := screen_data.mode if screen_data != null else ""
	# --- CUSTOM MATCH ---
	if mode == "custom_match":
		if selectors.size() == 1:
			print("🟧 Custom Match: P1 eligió su equipo. Creando CPU selector controlado por P1...")
			var cpu_selector := FLAG_SELECTOR_PREFAB.instantiate()
			cpu_selector.control_scheme = Player.ControlScheme.P1
			cpu_selector.is_cpu = true
			cpu_selector.is_selected = false
			cpu_selector.update_indicators()
			flags_container.add_child(cpu_selector)
			selectors.append(cpu_selector)
			cpu_selector.selected.connect(on_selector_selected.bind())
			cpu_selector.position = flags_container.get_child(0).position
			GameManager.player_setup.resize(2)
			GameManager.player_setup[1] = ""
			print("🤖 CPU listo para selección con controles de P1.")
			return

	# --- TOURNAMENT (1 jugador) ---
	if mode == "tournament" and selectors.size() == 1:
		print("🏆 Modo torneo (1 jugador): completando torneo automáticamente.")

		# --- Obtener los países disponibles ---
		var countries_full := DataLoader.get_countries()  # Array[String]
		var countries: Array[String] = []
		for i in range(1, 9):  # índices 1 a 8
			countries.append(countries_full[i])

		# --- Eliminar el país del jugador y mezclar el resto ---
		var player_country := GameManager.player_setup[0]
		countries.erase(player_country)
		countries.shuffle()

		# --- Crear un Array[String] seguro combinando P1 y rivales ---
		var tournament_countries: Array[String] = [player_country]
		for c in countries.slice(0, 7):
			tournament_countries.append(c)

		# --- Crear torneo ---
		var new_tournament := Tournament.new(false)
		new_tournament.matches.clear()
		new_tournament.create_bracket(Tournament.Stage.QUARTER_FINALS, tournament_countries)
		screen_data.set_tournament(new_tournament)
		print("✅ Torneo 1 jugador listo con 8 equipos.")
		transition_screen(SoccerGame.ScreenType.TOURNAMENT, screen_data)
		return

	# --- Resto: espera que ambos selectores estén listos ---
	for selector in selectors:
		if not selector.is_selected:
			return
	var country_p1 := GameManager.player_setup[0]
	var country_p2 := GameManager.player_setup[1]
	if country_p2.is_empty() or country_p1 == country_p2:
		push_warning("⚠️ Debes seleccionar dos equipos distintos.")
		return
	GameManager.current_match = Match.new(country_p2, country_p1)
	print("🎮 TeamSelectionScreen - Modo seleccionado:", mode)
	match mode:
		"animals_quiz":
			print("🐾 Iniciando ANIMALS_QUIZ...")
			transition_screen(SoccerGame.ScreenType.ANIMALS_QUIZ, screen_data)
		"soccer_quiz":
			print("⚽ Iniciando SOCCER_QUIZ...")
			transition_screen(SoccerGame.ScreenType.SOCCER_QUIZ, screen_data)
		"custom_match":
			print("🟧 Iniciando CUSTOM_MATCH (final directa)...")
			var custom_tournament := Tournament.new(true)
			custom_tournament.current_stage = Tournament.Stage.FINALS
			custom_tournament.matches = {
				Tournament.Stage.FINALS: [Match.new(country_p1, country_p2)],
				Tournament.Stage.COMPLETE: []
			}
			screen_data.set_tournament(custom_tournament)
			transition_screen(SoccerGame.ScreenType.CUSTOM_MATCH, screen_data)
		"tournament":
			print("🏆 Iniciando TOURNAMENT (modo 2 jugadores)...")
			var p1 := GameManager.player_setup[0]
			var p2 := GameManager.player_setup[1]
			var all_countries := DataLoader.get_countries()
			var available_countries: Array[String] = []
			# Tomamos solo países válidos (ignoramos posibles vacíos o placeholders)
			for i in range(1, all_countries.size()):
				if all_countries[i] != "" and all_countries[i] != null:
					available_countries.append(all_countries[i])
			# Quitamos los elegidos por los jugadores
			available_countries.erase(p1)
			available_countries.erase(p2)
			# Mezclamos y tomamos 6 rivales distintos
			available_countries.shuffle()
			var cpu_countries := available_countries.slice(0, 6)
			# ✅ Creamos lista final: jugadores primero para enfrentarse en el 1er match
			var tournament_countries: Array[String] = [p1, p2]
			tournament_countries.append_array(cpu_countries)
			print("🎮 Equipos del torneo (cuartos):", tournament_countries)
			# Creamos torneo manualmente
			var new_tournament := Tournament.new(false)
			new_tournament.matches.clear()
			new_tournament.create_bracket(Tournament.Stage.QUARTER_FINALS, tournament_countries)
			screen_data.set_tournament(new_tournament)
			transition_screen(SoccerGame.ScreenType.TOURNAMENT, screen_data)
		_:
			print("❌ Modo desconocido — volviendo al menú principal.")
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)
