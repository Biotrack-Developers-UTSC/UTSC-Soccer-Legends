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

# -----------------------
# 🔹 Brackets
# -----------------------
func refresh_brackets() -> void:
	for stage in Tournament.Stage.values():
		refresh_bracket_stage(stage)

func refresh_bracket_stage(stage: Tournament.Stage) -> void:
	var flag_nodes: Array[BracketFlag] = get_flag_nodes_for_stage(stage)
	var matches = tournament.matches.get(stage, [])

	for node in flag_nodes:
		node.visible = true
		node.texture = null
		node.border.visible = false
		node.score_label.visible = false
		node.modulate = Color(1, 1, 1, 1)

	if matches.is_empty():
		return

	var player1 := GameManager.player_setup[0]
	var player2 := GameManager.player_setup[1] if GameManager.player_setup.size() > 1 else ""

	for i in range(matches.size()):
		var match: Match = matches[i]
		var idx_home = i * 2
		var idx_away = i * 2 + 1
		if idx_home >= flag_nodes.size() or idx_away >= flag_nodes.size():
			continue

		var flag_home: BracketFlag = flag_nodes[idx_home]
		var flag_away: BracketFlag = flag_nodes[idx_away]

		flag_home.texture = FlagHelper.get_texture(match.country_home)
		flag_away.texture = FlagHelper.get_texture(match.country_away)
		flag_home.visible = true
		flag_away.visible = true

		if not match.winner.is_empty():
			var flag_winner = flag_home if match.winner == match.country_home else flag_away
			var flag_loser = flag_away if flag_winner == flag_home else flag_home
			var score = match.final_score if match.final_score != "" else "🏆"

			flag_winner.set_as_winner(score)
			flag_loser.set_as_loser(stage)

			flag_winner.border.visible = (match.winner == player1 or match.winner == player2) and stage != Tournament.Stage.COMPLETE
			flag_loser.score_label.visible = not ([match.country_home, match.country_away].has(player1) or [match.country_home, match.country_away].has(player2))
		else:
			if [match.country_home, match.country_away].has(player1) or [match.country_home, match.country_away].has(player2):
				var flag_player = flag_home if match.country_home in [player1, player2] else flag_away
				flag_player.set_as_current_team()
				GameManager.current_match = match

	for node in flag_nodes:
		if node.texture == null:
			node.modulate = Color(0.4, 0.4, 0.4, 1)

	if stage <= tournament.current_stage:
		_update_stage_texture(stage)

# -----------------------
# 🔹 Flags visibility
# -----------------------
func update_flags_visibility() -> void:
	for stage in Tournament.Stage.values():
		if not flag_containers.has(stage):
			continue
		for container in flag_containers[stage]:
			for child in container.get_children():
				if child is BracketFlag:
					child.visible = true
					if GameManager.current_match != null and not tournament.is_custom:
						child.border.visible = child.texture in [
							FlagHelper.get_texture(GameManager.current_match.country_home),
							FlagHelper.get_texture(GameManager.current_match.country_away)
						]
					else:
						child.border.visible = false
					child.score_label.visible = stage < tournament.current_stage and child.modulate.v > 0.6

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
		winner_flag.set_as_winner(final_score, true)

func get_flag_nodes_for_stage(stage: Tournament.Stage) -> Array[BracketFlag]:
	var nodes: Array[BracketFlag] = []
	if flag_containers.has(stage):
		for container in flag_containers[stage]:
			if container == null:
				continue
			for node in container.get_children():
				if node is BracketFlag:
					nodes.append(node)
	nodes.sort_custom(func(a, b): return a.position.y < b.position.y)
	return nodes

func _update_stage_texture(stage: Tournament.Stage = Tournament.Stage.QUARTER_FINALS) -> void:
	if stage == null:
		stage = tournament.current_stage
	if STAGE_TEXTURES.has(stage):
		stage_texture.texture = STAGE_TEXTURES[stage]
		stage_texture.visible = true
