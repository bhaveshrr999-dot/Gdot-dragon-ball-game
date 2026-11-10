class_name Roster
extends RefCounted

const GOKU_FORMS = ["Base", "Kaioken", "Super Saiyan", "Super Saiyan 2", "Super Saiyan 3", "Super Saiyan God", "Super Saiyan Blue", "Blue Kaioken", "Ultra Instinct Sign", "Mastered Ultra Instinct", "True Ultra Instinct"]
const VEGETA_FORMS = ["Base", "Super Saiyan", "Super Vegeta", "Super Saiyan 2", "Majin Vegeta", "Super Saiyan God", "Super Saiyan Blue", "Blue Evolution", "Ultra Ego"]
const ARENAS = ["Rocky Wasteland", "World Tournament", "Planet Namek", "Destroyed Namek", "Time Chamber", "Destroyed City", "Alien Battlefield"]
const MODES = ["Versus", "Training", "Story", "Survival", "Time Attack", "Local Battle", "Tournament", "Arcade", "Boss Battle", "Combo Trials"]
const DIFFICULTIES = ["Easy", "Normal", "Hard", "Legendary"]

static func forms(warrior: int) -> Array:
	return GOKU_FORMS if warrior == 0 else VEGETA_FORMS

static func form(warrior: int, index: int) -> Dictionary:
	var title: String = forms(warrior)[index]
	var hair := Color("11121e")
	var aura := Color("dcefff")
	if "Saiyan" in title or title == "Super Vegeta" or title == "Majin Vegeta":
		hair = Color("ffd34e")
		aura = Color("ffe378")
	if "God" in title:
		hair = Color("ed3656")
		aura = Color("ff6553")
	if "Blue" in title:
		hair = Color("36cfff")
		aura = Color("24bcff")
	if "Kaioken" in title:
		aura = Color("ff365c")
	if "Instinct" in title:
		aura = Color("dbe8ff")
		if "Mastered" in title:
			hair = Color("d8e5f5")
	if "Ego" in title:
		hair = Color("a24cf0")
		aura = Color("b04aff")
	return {"name": title, "hair": hair, "aura": aura, "power": 1.0 + index * 0.075, "speed": 1.0 + index * 0.025, "drain": index * 0.18, "evasion": 0.35 if "Instinct" in title else 0.0, "continuity": "Super manga" if title in ["True Ultra Instinct", "Ultra Ego"] else "Super anime" if title in ["Blue Kaioken", "Blue Evolution"] else "Manga / anime; era-dependent"}

static func attacks(warrior: int) -> Array:
	var blue := Color("40cfff")
	var gold := Color("ffdf5a")
	if warrior == 0:
		return [AttackDefinition.make("Kamehameha", 23, 24, "beam", blue), AttackDefinition.make("Super Kamehameha", 34, 34, "beam", blue, 0.8, 2), AttackDefinition.make("Kaioken Kamehameha", 31, 30, "beam", Color("ff4666"), 0.7, 1), AttackDefinition.make("Spirit Bomb", 44, 48, "sphere", blue, 1.9), AttackDefinition.make("Super Spirit Bomb", 60, 65, "sphere", blue, 2.8), AttackDefinition.make("Instant Transmission", 10, 18, "teleport", blue, 0.12), AttackDefinition.make("Dragon Fist · film / GT", 40, 42, "rush", gold, 0.6, 2), AttackDefinition.make("Warp Kamehameha", 38, 40, "warp", blue, 0.65), AttackDefinition.make("God Kamehameha", 43, 42, "beam", Color("ff647a"), 0.9, 5)]
	return [AttackDefinition.make("Galick Gun", 24, 24, "beam", Color("b079ff")), AttackDefinition.make("Final Flash", 42, 44, "beam", gold, 1.25, 1), AttackDefinition.make("Big Bang Attack", 30, 30, "sphere", blue, 0.55, 1), AttackDefinition.make("Final Explosion", 58, 65, "explosion", gold, 1.8, 4), AttackDefinition.make("Final Galick Gun", 43, 44, "beam", Color("bc7aff"), 1.1, 6), AttackDefinition.make("Gamma Burst Flash · manga", 45, 46, "beam", blue, 1.1, 6), AttackDefinition.make("Prominence Flash · game", 40, 40, "beam", Color("ff5b30"), 1.0, 5), AttackDefinition.make("Atomic Flash · game", 41, 42, "beam", gold, 1.0, 7), AttackDefinition.make("Ultra Ego Rush · fan-made", 48, 48, "rush", Color("ba62ff"), 0.6, 8)]
