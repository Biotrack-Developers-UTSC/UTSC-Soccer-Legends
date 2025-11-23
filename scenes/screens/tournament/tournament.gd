class_name Tournament
extends Node

enum Stage { QUARTER_FINALS, SEMI_FINALS, FINALS, COMPLETE }

var current_stage: Stage = Stage.QUARTER_FINALS
var matches := {} # Diccionario de Stage -> Array[Match]
var winner: String = ""
var is_custom: bool = false

func _init(custom_mode: bool = false) -> void:
	is_custom = custom_mode
	if is_custom:
		# Solo final para custom
		matches = { Stage.FINALS: [] }
		current_stage = Stage.FINALS
		print("🏁 Torneo custom inicializado (solo final).")
		return

	# Torneo normal de 8 países
	var countries := DataLoader.get_countries().slice(1, 9)
	countries.shuffle()
	create_bracket(Stage.QUARTER_FINALS, countries)

func create_bracket(stage: Stage, countries: Array[String]) -> void:
	matches[stage] = []
	for i in range(int(countries.size() / 2.0)):
		matches[stage].append(Match.new(countries[i * 2], countries[i * 2 + 1]))

func advance() -> void:
	if current_stage < Stage.COMPLETE:
		var stage_matches: Array = matches.get(current_stage, [])
		var stage_winners: Array[String] = []

		for current_match: Match in stage_matches:
			current_match.resolve()
			stage_winners.append(current_match.winner)

		current_stage = current_stage + 1 as Stage

		if current_stage == Stage.COMPLETE:
			winner = stage_winners[0]
		elif not is_custom:
			create_bracket(current_stage, stage_winners)
