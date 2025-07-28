extends Resource
class_name MapRulesResource

@export_category("Map Rules")
@export var high_walls:Array[String] = ["🧱"]
@export var breakable_high_walls:Array[String] = ["❌"]
@export var low_walls:Array[String] = ["🛡️", "🌵", "🪑", "🛏️"]
@export var high_doors:Array[String] = ["🚪"]
@export var enemy:Array[String] = ["🔫"]
@export var civilian:Array[String] = ["🙂"]
@export var dead_body:Array[String] = ["☠️"]
@export var money:Array[String] = ["💰"]
@export var water:Array[String] = ["🌊"]
@export var fog:Array[String] = ["⬛"]
@export var upstairs_marker:Array[String] = ["🔺"]
@export var downstairs_marker:Array[String] = ["🔻"]

func create_dict() -> Dictionary[String, Array]:
	return {
		"high_walls": high_walls,
		"breakable_high_walls": breakable_high_walls,
		"low_walls": low_walls,
		"high_doors": high_doors,
		"enemy": enemy,
		"civilian": civilian,
		"dead_body": dead_body,
		"money": money,
		"water": water,
		"fog": fog,
		"upstairs_marker": upstairs_marker,
		"downstairs_marker": downstairs_marker,
	}
