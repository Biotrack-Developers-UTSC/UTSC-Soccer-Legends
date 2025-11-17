class_name ScoreHelper

static func get_score_text(current_match: Match) -> String:
	return "%d - %d" % [current_match.goals_home, current_match.goals_away]

static func get_current_score_info(current_match: Match) -> String:
	if current_match.is_tied():
		return "LOS EQUIPOS VAN EMPATADOS! %d - %d" % [current_match.goals_home, current_match.goals_away]
	else:
		return "%s VA GANANDO! %s" % [current_match.winner, current_match.final_score]

static func get_final_score_info(current_match: Match) -> String:
	return "%s GANA EL PARTIDO!! %s" % [current_match.winner, current_match.final_score]
