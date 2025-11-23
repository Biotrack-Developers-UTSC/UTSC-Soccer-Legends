class_name CustomMatchScreen
extends Screen

const STAGE_TEXTURES := {
	Tournament.Stage.FINALS: preload("res://assets/art/ui/teamselection/finals-label.png"),
	Tournament.Stage.COMPLETE: preload("res://assets/art/ui/teamselection/winner-label.png"),
}

@onready var flag_containers: Dictionary = {
	Tournament.Stage.FINALS: [%FinalLeftContainer, %FinalRightContainer],
	Tournament.Stage.COMPLETE: [%WinnerContainer],
}

@onready var stage_texture: TextureRect = %StageTexture
@onready var stage_title_texture: TextureRect = %WorldCupTexture

var tournament: Tournament = null
var player_country: String = GameManager.player_setup[0]

func _ready() -> void:
	if screen_data == null:
		screen_data = ScreenData.build()

	if screen_data.tournament != null:
		tournament = screen_data.tournament
	else:
		tournament = Tournament.new(true)
		var match := Match.new(GameManager.player_setup[0], GameManager.player_setup[1])
		tournament.matches = { Tournament.Stage.FINALS: [match], Tournament.Stage.COMPLETE: [] }
		screen_data.tournament = tournament

	# Título siempre World Cup
	stage_title_texture.texture = preload("res://assets/art/ui/teamselection/worldcup-label.png")

	# Mostrar solo stages existentes en el torneo
	for stage in tournament.matches.keys():
		refresh_bracket_stage(stage)

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


func refresh_brackets() -> void:
	if tournament == null or tournament.matches.is_empty():
		return
	for stage in tournament.matches.keys():
		refresh_bracket_stage(stage)


func refresh_bracket_stage(stage: Tournament.Stage) -> void:
	var flag_nodes := get_flag_nodes_for_stage(stage)
	if flag_nodes.is_empty():
		return

	var matches: Array = tournament.matches.get(stage, [])

	# Mostrar todos los flags, aunque no haya partidos
	for node in flag_nodes:
		node.visible = false
		node.modulate = Color(1,1,1,1)
		node.border.visible = false
		node.score_label.visible = false

	for i in range(matches.size()):
		if 2*i >= flag_nodes.size() or 2*i+1 >= flag_nodes.size():
			continue
		var current_match: Match = matches[i]
		var flag_home: BracketFlag = flag_nodes[2*i]
		var flag_away: BracketFlag = flag_nodes[2*i+1]

		flag_home.visible = true
		flag_away.visible = true
		flag_home.texture = FlagHelper.get_texture(current_match.country_home)
		flag_away.texture = FlagHelper.get_texture(current_match.country_away)

		if not current_match.winner.is_empty():
			var flag_winner := flag_home if current_match.winner == current_match.country_home else flag_away
			var flag_loser := flag_home if flag_winner == flag_away else flag_away
			flag_winner.set_as_winner(current_match.final_score)
			flag_loser.set_as_loser()
		elif [current_match.country_home, current_match.country_away].has(player_country) and stage == tournament.current_stage:
			var flag_player := flag_home if current_match.country_home == player_country else flag_away
			flag_player.set_as_current_team()
			GameManager.current_match = current_match


func show_winner_if_complete() -> void:
	var winner_stage := Tournament.Stage.FINALS if tournament.is_custom else Tournament.Stage.COMPLETE
	if tournament.winner == "":
		return
	MusicPlayer.play_music(MusicPlayer.Music.WIN)
	var winner_nodes: Array = get_flag_nodes_for_stage(winner_stage)
	if winner_nodes.size() > 0:
		var winner_flag: BracketFlag = winner_nodes[0]
		winner_flag.visible = true
		winner_flag.texture = FlagHelper.get_texture(tournament.winner)

		var finals_matches: Array = tournament.matches.get(Tournament.Stage.FINALS, [])
		var final_score: String = finals_matches[0].final_score if finals_matches.size() > 0 else "🏆"
		winner_flag.set_as_winner(final_score)


func get_flag_nodes_for_stage(stage: Tournament.Stage) -> Array[BracketFlag]:
	var flag_nodes: Array[BracketFlag] = []
	if flag_containers.has(stage):
		for container in flag_containers[stage]:
			for node in container.get_children():
				if node is BracketFlag:
					flag_nodes.append(node)
	return flag_nodes
