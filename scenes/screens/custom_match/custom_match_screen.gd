class_name CustomMatchScreen
extends Screen

const STAGE_TEXTURES := {
	Tournament.Stage.FINALS: preload("res://assets/art/ui/teamselection/finals-label.png"),
	Tournament.Stage.COMPLETE: preload("res://assets/art/ui/teamselection/winner-label.png"),
}

@onready var flag_containers: Dictionary = {
	Tournament.Stage.QUARTER_FINALS: [%QFLeftContainer, %QFRightContainer],
	Tournament.Stage.SEMI_FINALS: [%SFLeftContainer, %SFRightContainer],
	Tournament.Stage.FINALS: [%FinalLeftContainer, %FinalRightContainer],
	Tournament.Stage.COMPLETE: [%WinnerContainer],
}

@onready var stage_texture: TextureRect = %StageTexture
@onready var stage_title_texture: TextureRect = %WorldCupTexture

var tournament: Tournament = null

func _ready() -> void:
	if screen_data == null:
		screen_data = ScreenData.build()

	if screen_data.tournament != null:
		tournament = screen_data.tournament
	else:
		# Crear torneo dummy solo con la final
		tournament = Tournament.new(true)
		var p1 = GameManager.player_setup[0]
		var p2 = GameManager.player_setup[1] if GameManager.player_setup.size() > 1 else ""
		
		var match_custom := Match.new(p1, p2)
		tournament.matches = { Tournament.Stage.FINALS: [match_custom], Tournament.Stage.COMPLETE: [] }
		screen_data.tournament = tournament

	# Título "World Cup"
	if stage_title_texture:
		stage_title_texture.texture = preload("res://assets/art/ui/teamselection/worldcup-label.png")

	refresh_brackets()
	show_winner_if_complete()

func _process(_delta: float) -> void:
	if KeyUtils.is_action_just_pressed(Player.ControlScheme.P1, KeyUtils.Action.SHOOT):
		if tournament.current_stage < Tournament.Stage.COMPLETE:
			var stage_matches: Array = tournament.matches.get(Tournament.Stage.FINALS, [])
			if stage_matches.size() > 0:
				GameManager.current_match = stage_matches[0]
				transition_screen(SoccerGame.ScreenType.IN_GAME, screen_data)
		else:
			transition_screen(SoccerGame.ScreenType.TOURNAMENT, screen_data)
		SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)

# -----------------------
# 🔹 Actualización de Brackets
# -----------------------
func refresh_brackets() -> void:
	if tournament == null: return
	
	for stage in Tournament.Stage.values():
		refresh_bracket_stage(stage)

func refresh_bracket_stage(stage: Tournament.Stage) -> void:
	var flag_nodes := get_flag_nodes_for_stage(stage)
	if flag_nodes.is_empty(): return

	# 🙈 CASO 1: Cuartos y Semis semitransparentes (como en Tournament)
	if stage == Tournament.Stage.QUARTER_FINALS or stage == Tournament.Stage.SEMI_FINALS:
		for node in flag_nodes:
			if node is BracketFlag:
				node.visible = true  # Mantiene su posición en el layout
				node.border.visible = false
				node.score_label.visible = false

				var placeholder_tex = FlagHelper.get_texture("placeholder")
				if placeholder_tex != null:
					node.texture = placeholder_tex
					node.modulate = Color(1, 1, 1, 0.5)  # Semitransparente
				else:
					node.texture = null
					node.modulate = Color(0, 0, 0, 0)    # Invisible si no hay textura
		return

	# 🏁 CASO 2: Etapa Final (La que nos interesa)
	var matches: Array = tournament.matches.get(stage, [])
	if matches.is_empty(): return

	for i in range(matches.size()):
		var idx_home = 2 * i
		var idx_away = 2 * i + 1
		if idx_away >= flag_nodes.size(): break

		var current_match: Match = matches[i]
		var flag_home: BracketFlag = flag_nodes[idx_home]
		var flag_away: BracketFlag = flag_nodes[idx_away]

		# Configurar Visuales
		_setup_flag_visuals(flag_home, current_match.country_home)
		_setup_flag_visuals(flag_away, current_match.country_away)

		# Lógica de Ganador y Bordes
		if not current_match.winner.is_empty():
			var flag_winner := flag_home if current_match.winner == current_match.country_home else flag_away
			var flag_loser := flag_home if flag_winner == flag_away else flag_away
			flag_winner.set_as_winner(current_match.final_score)
			flag_loser.set_as_loser(stage)
			flag_winner.border.visible = current_match.winner in GameManager.player_setup
		else:
			flag_home.border.visible = false
			flag_away.border.visible = false
			
			# Borde JUGADOR 1
			if current_match.country_home == GameManager.player_setup[0]:
				flag_home.set_as_current_team()
				
			# Borde JUGADOR 2
			if GameManager.player_setup.size() > 1 and current_match.country_away == GameManager.player_setup[1]:
				flag_away.set_as_current_team()
			
			if flag_home.border.visible or flag_away.border.visible:
				GameManager.current_match = current_match

# -----------------------
# 🏆 Mostrar Ganador
# -----------------------
func show_winner_if_complete() -> void:
	if tournament.winner.is_empty(): return
	
	var winner_nodes: Array = get_flag_nodes_for_stage(Tournament.Stage.COMPLETE)
	if winner_nodes.size() > 0:
		MusicPlayer.play_music(MusicPlayer.Music.WIN)
		var winner_flag: BracketFlag = winner_nodes[0]
		
		_setup_flag_visuals(winner_flag, tournament.winner)

		var finals_matches: Array = tournament.matches.get(Tournament.Stage.FINALS, [])
		var final_score: String = finals_matches[0].final_score if finals_matches.size() > 0 else "🏆"
		winner_flag.set_as_winner(final_score, true)

# -----------------------
# 🎨 Helper Visual
# -----------------------
func _setup_flag_visuals(node: BracketFlag, country_name: String) -> void:
	node.visible = true
	node.border.visible = false
	node.score_label.visible = false
	
	var tex = FlagHelper.get_texture(country_name)
	if tex != null:
		node.texture = tex
		node.modulate = Color.WHITE
	else:
		print("⚠️ CustomMatch: Falta textura para ", country_name)
		var p = FlagHelper.get_texture("placeholder")
		if p:
			node.texture = p
			node.modulate = Color(1, 1, 1, 0.5) # Semitransparente si no existe
		else:
			node.texture = null
			node.modulate = Color(0, 0, 0, 0)

# -----------------------
# 🧩 Obtener Nodos de Banderas
# -----------------------
func get_flag_nodes_for_stage(stage: Tournament.Stage) -> Array[BracketFlag]:
	var flag_nodes: Array[BracketFlag] = []
	if flag_containers.has(stage):
		for container in flag_containers[stage]:
			if container == null: continue
			for node in container.get_children():
				if node is BracketFlag:
					flag_nodes.append(node)
	return flag_nodes
