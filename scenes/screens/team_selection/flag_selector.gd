class_name FlagSelector
extends Control

signal selected

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var indicator_1p: TextureRect = %Indicator1P
@onready var indicator_2p: TextureRect = %Indicator2P
@onready var indicator_cpu: TextureRect = %IndicatorCPU

var control_scheme: Player.ControlScheme = Player.ControlScheme.P1
var is_selected: bool = false
var is_cpu: bool = false # 👈 Nuevo estado para CPU

func _ready() -> void:
	update_indicators()

func update_indicators() -> void:
	if indicator_1p:
		indicator_1p.visible = not is_cpu and control_scheme == Player.ControlScheme.P1
	if indicator_2p:
		indicator_2p.visible = not is_cpu and control_scheme == Player.ControlScheme.P2
	if indicator_cpu:
		indicator_cpu.visible = is_cpu

func _process(_delta: float) -> void:
	# Confirmar selección
	if not is_selected and KeyUtils.is_action_just_pressed(control_scheme, KeyUtils.Action.SHOOT):
		is_selected = true
		animation_player.play("selected")
		SoundPlayer.play(SoundPlayer.Sound.UI_SELECT)
		print("✅ FlagSelector seleccionado por:", control_scheme, (" (CPU)" if is_cpu else ""))
		emit_signal("selected")

	# Cancelar selección
	elif is_selected and KeyUtils.is_action_just_pressed(control_scheme, KeyUtils.Action.PASS):
		is_selected = false
		animation_player.play("selecting")
		SoundPlayer.play(SoundPlayer.Sound.UI_NAV)
		print("↩️ FlagSelector deseleccionado por:", control_scheme)
