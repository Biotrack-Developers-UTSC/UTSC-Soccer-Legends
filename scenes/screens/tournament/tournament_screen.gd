class_name TournamentScreen
extends Screen

const STAGE_TEXTURES := {
	Tournament.Stage.QUARTER_FINALS: preload("res://assets/art/ui/teamselection/quarters-label.png"),
	Tournament.Stage.SEMI_FINALS: preload("res://assets/art/ui/teamselection/semis-label.png"),
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
var tournament: Tournament = null

func _ready() -> void:
	# Esperar un frame para el cálculo de posiciones globales
	await get_tree().process_frame
	
	tournament = screen_data.tournament if screen_data.tournament != null else Tournament.new(true)
	screen_data.tournament = tournament

	if tournament.current_stage == Tournament.Stage.COMPLETE:
		stage_texture.texture = STAGE_TEXTURES[Tournament.Stage.COMPLETE]
		MusicPlayer.play_music(MusicPlayer.Music.WIN)

	refresh_brackets()
	show_winner_if_complete()

func _process(_delta: float) -> void:
	if KeyUtils.is_action_just_pressed(Player.ControlScheme.P1, KeyUtils.Action.SHOOT):
		if tournament.current_stage < Tournament.Stage.COMPLETE:
			var stage_matches = tournament.matches.get(tournament.current_stage, [])
			if stage_matches.size() > 0:
				GameManager.current_match = stage_matches[0]
				transition_screen(SoccerGame.ScreenType.IN_GAME, screen_data)
		else:
			transition_screen(SoccerGame.ScreenType.MAIN_MENU)
		SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)

# -----------------------
# 🔹 Lógica de Brackets
# -----------------------
func refresh_brackets() -> void:
	for stage in Tournament.Stage.values():
		refresh_bracket_stage(stage)

func refresh_bracket_stage(stage: Tournament.Stage) -> void:
	var flag_nodes := get_flag_nodes_for_stage(stage)
	
	if stage == tournament.current_stage:
		stage_texture.texture = STAGE_TEXTURES.get(stage)

	if stage < Tournament.Stage.COMPLETE:
		var matches : Array = tournament.matches.get(stage, [])
		
		# --- CASO A: Placeholders ---
		if matches.is_empty():
			for node in flag_nodes:
				if node is BracketFlag:
					_setup_flag_visuals(node, "", true) 
			return

		# --- CASO B: Partidos ---
		for i in range(matches.size()):
			var idx_home = 2 * i
			var idx_away = 2 * i + 1
			
			if idx_away >= flag_nodes.size(): break 

			var current_match : Match = matches[i]
			var flag_home : BracketFlag = flag_nodes[idx_home]
			var flag_away : BracketFlag = flag_nodes[idx_away]

			_setup_flag_visuals(flag_home, current_match.country_home, false)
			_setup_flag_visuals(flag_away, current_match.country_away, false)

			if not current_match.winner.is_empty():
				# Partido Terminado
				var flag_winner := flag_home if current_match.winner == current_match.country_home else flag_away
				var flag_loser := flag_home if flag_winner == flag_away else flag_away
				var score = current_match.final_score if current_match.final_score != "" else "🏆"
				
				flag_winner.set_as_winner(score)
				flag_loser.set_as_loser(stage)
				
				# En match terminado, borde solo para el ganador si es humano
				flag_winner.border.visible = current_match.winner in GameManager.player_setup
			else:
				# Partido Pendiente (Aquí arreglamos los bordes de P1 y P2)
				flag_home.border.visible = false
				flag_away.border.visible = false
				
				# Revisamos al equipo HOME
				if current_match.country_home in GameManager.player_setup:
					flag_home.set_as_current_team()
				
				# Revisamos al equipo AWAY (Independiente, para que ambos puedan tener borde)
				if current_match.country_away in GameManager.player_setup:
					flag_away.set_as_current_team()
				
				if flag_home.border.visible or flag_away.border.visible:
					GameManager.current_match = current_match
	else:
		# --- CASO C: Winner (El cuadro del medio abajo) ---
		if flag_nodes.size() > 0:
			# Si no hay ganador todavía, le decimos que es placeholder (true)
			var is_empty = tournament.winner.is_empty()
			_setup_flag_visuals(flag_nodes[0], tournament.winner, is_empty)

# Helper visual
func _setup_flag_visuals(node: BracketFlag, country_name: String, is_placeholder: bool) -> void:
	node.visible = true 
	node.border.visible = false
	node.score_label.visible = false
	
	# --- CASO 1: Placeholders (Cuadros vacíos o futuros) ---
	if is_placeholder:
		var p = FlagHelper.get_texture("placeholder")
		if p != null:
			node.texture = p
			node.modulate = Color(1, 1, 1, 0.5) # Semitransparente
		else:
			# Si no hay imagen placeholder, lo hacemos invisible
			node.texture = null
			node.modulate = Color(0, 0, 0, 0) 
		return

	# --- CASO 2: Equipos Reales ---
	var tex = FlagHelper.get_texture(country_name)
	
	if tex != null:
		node.texture = tex
		node.modulate = Color.WHITE
	else:
		# Fallback si falta imagen (Error)
		print("⚠️ TEXTURA FALTANTE para: ", country_name)
		# Ponemos el placeholder para que no se vea morado
		node.texture = FlagHelper.get_texture("placeholder")
		node.modulate = Color(1, 1, 1, 1) 

func show_winner_if_complete() -> void:
	if tournament.winner.is_empty(): return
	tournament.current_stage = Tournament.Stage.COMPLETE
	stage_texture.texture = STAGE_TEXTURES[Tournament.Stage.COMPLETE]
	var winner_nodes = get_flag_nodes_for_stage(Tournament.Stage.COMPLETE)
	if winner_nodes.size() > 0:
		_setup_flag_visuals(winner_nodes[0], tournament.winner, false)
		var finals_matches = tournament.matches.get(Tournament.Stage.FINALS, [])
		var final_score = finals_matches[0].final_score if finals_matches.size() > 0 else "🏆"
		winner_nodes[0].set_as_winner(final_score, true)

func get_flag_nodes_for_stage(stage: Tournament.Stage) -> Array[BracketFlag]:
	var final_ordered_nodes: Array[BracketFlag] = []
	if not flag_containers.has(stage):
		return final_ordered_nodes

	var containers = flag_containers[stage]
	
	for container in containers:
		if container == null: continue
		
		var side_nodes: Array[BracketFlag] = []
		for node in container.get_children():
			if node is BracketFlag:
				side_nodes.append(node)
		
		side_nodes.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
		final_ordered_nodes.append_array(side_nodes)
	
	return final_ordered_nodes

func _update_stage_texture(stage: Tournament.Stage = Tournament.Stage.QUARTER_FINALS) -> void:
	if stage == null: stage = tournament.current_stage
	if STAGE_TEXTURES.has(stage):
		stage_texture.texture = STAGE_TEXTURES[stage]
		stage_texture.visible = true
