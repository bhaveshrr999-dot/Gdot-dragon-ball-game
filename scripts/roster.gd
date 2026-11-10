class_name Roster
extends RefCounted

const GOKU_FORMS = ["Base", "Kaioken", "Super Saiyan", "Super Saiyan 2", "Super Saiyan 3", "Super Saiyan God", "Super Saiyan Blue", "Blue Kaioken", "Ultra Instinct Sign", "Mastered Ultra Instinct", "True Ultra Instinct"]
const VEGETA_FORMS = ["Base", "Super Saiyan", "Super Vegeta", "Super Saiyan 2", "Majin Vegeta", "Super Saiyan God", "Super Saiyan Blue", "Blue Evolution", "Ultra Ego"]
const ARENAS = ["Rocky Wasteland", "World Tournament", "Planet Namek", "Destroyed Namek", "Time Chamber", "Destroyed City", "Alien Battlefield"]
const MODES = ["Versus", "Training", "Story", "Survival", "Time Attack", "Local Battle", "Tournament", "Arcade", "Boss Battle", "Combo Trials"]
const DIFFICULTIES = ["Easy", "Normal", "Hard", "Legendary"]

# Balance values are game design, not canonical numerical power multipliers.
# power, speed, ki drain/sec, damage received, stamina recovery, evade chance, strain/sec
const GOKU_BALANCE = [[1.0, 1.0, 0.0, 1.0, 10.0, 0.0, 0.0, 'Balanced · passive Ki recovery'],
 [1.28, 1.18, 2.8, 1.0, 8.0, 0.0, 1.2, 'Burst power · drains health and Ki'],
 [1.45, 1.1, 1.8, 0.94, 11.0, 0.0, 0.0, 'Sustained strength · efficient stamina'],
 [1.7, 1.18, 2.7, 0.91, 11.0, 0.0, 0.0, 'Fast pressure · higher Ki upkeep'],
 [2.05, 1.12, 6.8, 0.88, 7.0, 0.0, 0.0, 'Heavy output · severe Ki upkeep'],
 [2.2, 1.24, 1.5, 0.85, 14.0, 0.0, 0.0, 'Godly control · efficient recovery'],
 [2.4, 1.22, 3.8, 0.83, 12.0, 0.0, 0.0, 'Precision · reduced special Ki cost'],
 [2.75, 1.38, 7.5, 0.86, 7.0, 0.0, 2.0, 'Explosive speed · severe body strain'],
 [2.55, 1.34, 4.8, 0.9, 13.0, 0.22, 0.0, 'Automatic evasion · consumes Ki'],
 [2.95, 1.42, 6.0, 0.8, 15.0, 0.4, 0.0, 'Evasion and counters · high Ki upkeep'],
 [2.8, 1.36, 4.4, 0.86, 14.0, 0.28, 0.0, 'Instinct in motion · balanced endurance']]
const VEGETA_BALANCE = [[1.0, 1.0, 0.0, 1.0, 10.0, 0.0, 0.0, 'Balanced · passive Ki recovery'],
 [1.45, 1.1, 1.8, 0.94, 11.0, 0.0, 0.0, 'Sustained strength · efficient stamina'],
 [1.65, 1.05, 3.3, 0.85, 8.0, 0.0, 0.0, 'Bulky power · slower movement'],
 [1.7, 1.18, 2.7, 0.91, 11.0, 0.0, 0.0, 'Fast pressure · higher Ki upkeep'],
 [1.8, 1.18, 3.6, 0.88, 10.0, 0.0, 0.0, 'Relentless offense · increased upkeep'],
 [2.2, 1.24, 1.5, 0.85, 14.0, 0.0, 0.0, 'Godly control · efficient recovery'],
 [2.4, 1.22, 3.8, 0.83, 12.0, 0.0, 0.0, 'Precision · reduced special Ki cost'],
 [2.7, 1.23, 5.8, 0.78, 10.0, 0.0, 0.0, 'Armored pressure · high Ki upkeep'],
 [2.4, 1.16, 4.5, 1.08, 12.0, 0.0, 0.0, 'Damage builds fury · no healing or immunity']]

static func hair_style(warrior: int, index: int) -> String:
	if warrior == 1: return "base"
	if index == 4: return "long"
	return "raised" if index in [2,3,6,7] else "base"

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
	var stats: Array = (GOKU_BALANCE if warrior == 0 else VEGETA_BALANCE)[index]
	return {"name": title, "hair": hair, "aura": aura, "power": stats[0], "speed": stats[1], "drain": stats[2], "defense": stats[3], "stamina_regen": stats[4], "evasion": stats[5], "strain": stats[6], "description": stats[7], "ki_cost": 0.85 if title == "Super Saiyan Blue" else 1.0, "continuity": "Super manga" if title in ["True Ultra Instinct", "Ultra Ego"] else "Super anime" if title in ["Blue Kaioken", "Blue Evolution"] else "Manga / anime; era-dependent"}


static func attacks(warrior: int) -> Array:
	var blue := Color("40cfff")
	var gold := Color("ffdf5a")
	if warrior == 0:
		return [AttackDefinition.make("Kamehameha", 23, 24, "beam", blue), AttackDefinition.make("Super Kamehameha", 34, 34, "beam", blue, 0.8, 2), AttackDefinition.make("Kaioken Kamehameha", 31, 30, "beam", Color("ff4666"), 0.7, 1), AttackDefinition.make("Spirit Bomb", 44, 48, "sphere", blue, 1.9), AttackDefinition.make("Super Spirit Bomb", 60, 65, "sphere", blue, 2.8), AttackDefinition.make("Instant Transmission", 10, 18, "teleport", blue, 0.12), AttackDefinition.make("Dragon Fist · film / GT", 40, 42, "rush", gold, 0.6, 2), AttackDefinition.make("Warp Kamehameha", 38, 40, "warp", blue, 0.65), AttackDefinition.make("God Kamehameha", 43, 42, "beam", Color("ff647a"), 0.9, 5)]
	return [AttackDefinition.make("Galick Gun", 24, 24, "beam", Color("b079ff")), AttackDefinition.make("Final Flash", 42, 44, "beam", gold, 1.25, 1), AttackDefinition.make("Big Bang Attack", 30, 30, "sphere", blue, 0.55, 1), AttackDefinition.make("Final Explosion", 58, 65, "explosion", gold, 1.8, 4), AttackDefinition.make("Final Galick Gun", 43, 44, "beam", Color("bc7aff"), 1.1, 6), AttackDefinition.make("Gamma Burst Flash · manga", 45, 46, "beam", blue, 1.1, 6), AttackDefinition.make("Prominence Flash · game", 40, 40, "beam", Color("ff5b30"), 1.0, 5), AttackDefinition.make("Atomic Flash · game", 41, 42, "beam", gold, 1.0, 7), AttackDefinition.make("Ultra Ego Rush · fan-made", 48, 48, "rush", Color("ba62ff"), 0.6, 8)]
