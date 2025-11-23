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
var player_country: String = GameManager.player_setup[0]

func _ready() -> void:
	tournament = screen_data.tournament if screen_data.tournament != null else Tournament.new(true)
	screen_data.tournament = tournament

	# Si el torneo ya terminó
	if tournament.current_stage == Tournament.Stage.COMPLETE:
		stage_texture.texture = STAGE_TEXTURES[Tournament.Stage.COMPLETE]
		MusicPlayer.play_music(MusicPlayer.Music.WIN)

	refresh_brackets()
	show_winner_if_complete()
	update_flags_visibility()


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

func refresh_brackets() -> void:
	for stage in Tournament.Stage.values():
		refresh_bracket_stage(stage)

func refresh_bracket_stage(stage: Tournament.Stage) -> void:
	var flag_nodes: Array[BracketFlag] = get_flag_nodes_for_stage(stage)
	var matches = tournament.matches.get(stage, [])

	# Actualizar textura de stage
	if stage == Tournament.Stage.COMPLETE:
		stage_texture.texture = STAGE_TEXTURES[Tournament.Stage.COMPLETE]
	elif matches.size() > 0:
		stage_texture.texture = STAGE_TEXTURES[stage]

	for i in range(flag_nodes.size()):
		var node: BracketFlag = flag_nodes[i]
		node.texture = null
		node.border.visible = false
		node.score_label.visible = false
		node.visible = true

	# Mostrar los partidos existentes
	for i in range(matches.size()):
		if 2*i >= flag_nodes.size() or 2*i+1 >= flag_nodes.size():
			continue
		var match: Match = matches[i]
		var flag_home: BracketFlag = flag_nodes[2*i]
		var flag_away: BracketFlag = flag_nodes[2*i+1]

		flag_home.texture = FlagHelper.get_texture(match.country_home)
		flag_away.texture = FlagHelper.get_texture(match.country_away)

		if not match.winner.is_empty():
			var flag_winner = flag_home if match.winner == match.country_home else flag_away
			var flag_loser = flag_home if flag_winner == flag_away else flag_away
			var score = match.final_score if match.final_score != "" else "🏆"
			flag_winner.set_as_winner(score)
			flag_loser.set_as_loser()
		elif [match.country_home, match.country_away].has(player_country) and stage == tournament.current_stage:
			var flag_player = flag_home if match.country_home == player_country else flag_away
			flag_player.set_as_current_team()
			GameManager.current_match = match

func update_flags_visibility() -> void:
	for stage in Tournament.Stage.values():
		if not flag_containers.has(stage):
			continue
		for container in flag_containers[stage]:
			for child in container.get_children():
				if child is BracketFlag:
					if tournament.is_custom:
						# Solo mostrar BracketFlags de Finals y Winner
						child.visible = stage == Tournament.Stage.FINALS or stage == Tournament.Stage.COMPLETE
						child.border.visible = false
						child.score_label.visible = false
					else:
						# Tournament normal: siempre visible
						child.visible = true
						# Bordes solo para el match actual
						if GameManager.current_match != null:
							if child.texture in [
								FlagHelper.get_texture(GameManager.current_match.country_home),
								FlagHelper.get_texture(GameManager.current_match.country_away)
							]:
								child.border.visible = true
							else:
								child.border.visible = false
						# Scores visibles solo si la etapa ya pasó
						child.score_label.visible = stage < tournament.current_stage
				else:
					# Paddings y links: visibles solo en tournament
					child.visible = not tournament.is_custom

func show_winner_if_complete() -> void:
	if tournament.winner.is_empty():
		return

	tournament.current_stage = Tournament.Stage.COMPLETE
	stage_texture.texture = STAGE_TEXTURES[Tournament.Stage.COMPLETE]

	var winner_nodes = get_flag_nodes_for_stage(Tournament.Stage.COMPLETE)
	if winner_nodes.size() > 0:
		var winner_flag: BracketFlag = winner_nodes[0]
		winner_flag.visible = true
		winner_flag.texture = FlagHelper.get_texture(tournament.winner)

		var finals_matches = tournament.matches.get(Tournament.Stage.FINALS, [])
		var final_score = finals_matches[0].final_score if finals_matches.size() > 0 else "🏆"
		winner_flag.set_as_winner(final_score)

	# Ocultar controles de todos los flags si es custom
	if tournament.is_custom:
		for stage in Tournament.Stage.values():
			for node in get_flag_nodes_for_stage(stage):
				node.border.visible = false
				node.score_label.visible = false

func get_flag_nodes_for_stage(stage: Tournament.Stage) -> Array[BracketFlag]:
	var nodes: Array[BracketFlag] = []
	if flag_containers.has(stage):
		for container in flag_containers[stage]:
			for node in container.get_children():
				if node is BracketFlag:
					nodes.append(node)
	return nodes
