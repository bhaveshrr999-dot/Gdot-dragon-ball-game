class_name AttackDefinition
extends Resource

@export var title: String
@export var damage: float = 20.0
@export var cost: float = 25.0
@export var startup: float = 0.5
@export var recovery: float = 0.7
@export var kind: String = "beam"
@export var color: Color = Color.CYAN
@export var minimum_form: int = 0

static func make(label: String, power: float, energy: float, type: String, tint: Color, windup: float = 0.5, form: int = 0) -> AttackDefinition:
	var attack := AttackDefinition.new()
	attack.title = label
	attack.damage = power
	attack.cost = energy
	attack.kind = type
	attack.color = tint
	attack.startup = windup
	attack.minimum_form = form
	return attack
