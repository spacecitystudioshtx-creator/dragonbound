## Programmatic NPC factory. Autoloaded as NPCSpawner.
##
## Usage:
##   NPCSpawner.spawn(parent, tile_x, tile_y, face_dir, dialog_file, node_id)
##
## The spawned NPC is a Node2D with:
##   - Sprite2D at tile center, frame set by face direction
##   - Area2D in the "interactable" group so player.gd's _try_interact() finds it
##
## Face directions map to spritesheet rows on npc_samurai.png (4-frame strips):
##   DOWN=0, LEFT=1, RIGHT=2, UP=3

extends Node

const TILE    := 16
const NPC_TEX := "res://art/characters/npc_samurai.png"

## Direction → spritesheet row index
const FACE_ROW := {
	Vector2.DOWN:  0,
	Vector2.LEFT:  1,
	Vector2.RIGHT: 2,
	Vector2.UP:    3,
}

## Spawn an NPC at tile (tile_x, tile_y) facing face_dir.
## Returns the Node2D root so callers can hold a ref if needed.
func spawn(parent: Node, tile_x: int, tile_y: int,
		face_dir: Vector2, dialog_file: String, node_id: String) -> Node2D:

	var npc := Node2D.new()
	npc.name    = "NPC_" + node_id
	npc.position = Vector2(tile_x * TILE + TILE / 2, tile_y * TILE + TILE / 2)
	npc.z_index  = int(npc.position.y)   ## y-sort with player
	parent.add_child(npc)

	## Sprite
	var sprite := Sprite2D.new()
	if ResourceLoader.exists(NPC_TEX):
		sprite.texture = load(NPC_TEX)
		sprite.hframes = 4
		sprite.vframes = 7   ## sheet is 4-col × 7-row (same layout as player_sheet.png)
		sprite.frame   = FACE_ROW.get(face_dir, 0) * 4
	else:
		## Fallback: colored square so the NPC is still visible
		var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
		img.fill(ThemeColors.RED_EMBER)
		sprite.texture = ImageTexture.create_from_image(img)
	sprite.centered = true
	npc.add_child(sprite)

	## Interaction Area2D — placed at tile center, radius slightly under 1 tile
	var area := Area2D.new()
	area.name = "InteractArea"
	area.add_to_group("interactable")
	area.set_meta("dialog_file", dialog_file)
	area.set_meta("node_id",     node_id)
	area.position = Vector2.ZERO   ## inherits npc position

	var cshape := CollisionShape2D.new()
	var shape  := CircleShape2D.new()
	shape.radius = float(TILE) * 0.45
	cshape.shape = shape
	area.add_child(cshape)
	npc.add_child(area)

	## Solid body so the player can't walk through the NPC
	var body   := StaticBody2D.new()
	body.collision_layer = 2
	body.collision_mask  = 0
	var bshape := CollisionShape2D.new()
	var brect  := RectangleShape2D.new()
	brect.size = Vector2(TILE - 2, TILE - 2)
	bshape.shape = brect
	body.add_child(bshape)
	npc.add_child(body)

	return npc
