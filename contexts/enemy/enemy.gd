## INIMIGO parado com pontos sensiveis. E UM corpo fisico so (RigidBody3D, congelado em pe) com uma
## forma de colisao por parte do corpo (29 partes, incluindo as articulacoes em cinza), cada uma com vida propria.
## A arma chama take_hit() quando o tiro acerta. Parte sem vida:
##   - tudo que nao e nucleo se solta do corpo e vira um pedaco fisico que voa, LEVANDO JUNTO
##     o que vem depois na cadeia (CHAINS): joelho arrancado leva canela, tornozelo e pe;
##   - peito, abdomen e pelve nao se soltam (sao o nucleo do corpo);
##   - qualquer parte exceto as do braco: o inimigo cai (descongela e tomba na direcao do tiro).
## Sangue: particulas (blood.tscn) a cada tiro e manchas no chao/parede (blood_stain.tscn).
## Os nomes das partes precisam ser iguais aos dos nos CollisionShape3D em enemy.tscn.
extends RigidBody3D

## Vida de cada parte. Articulacoes sao frageis de proposito.
const PART_HP := {
	"Head": 20.0, "Neck": 15.0,
	"Chest": 60.0, "Abdomen": 40.0, "Pelvis": 40.0,
	"ShoulderL": 20.0, "UpperArmL": 20.0, "ElbowL": 12.0, "ForearmL": 15.0, "WristL": 8.0, "HandL": 10.0,
	"ShoulderR": 20.0, "UpperArmR": 20.0, "ElbowR": 12.0, "ForearmR": 15.0, "WristR": 8.0, "HandR": 10.0,
	"HipL": 25.0, "ThighL": 25.0, "KneeL": 15.0, "ShinL": 20.0, "AnkleL": 10.0, "FootL": 10.0,
	"HipR": 25.0, "ThighR": 25.0, "KneeR": 15.0, "ShinR": 20.0, "AnkleR": 10.0, "FootR": 10.0,
}
## Cadeias do corpo, de cima pra baixo. Quando uma parte se solta, tudo que vem DEPOIS dela sai junto.
const CHAINS := [
	["Neck", "Head"],
	["ShoulderL", "UpperArmL", "ElbowL", "ForearmL", "WristL", "HandL"],
	["ShoulderR", "UpperArmR", "ElbowR", "ForearmR", "WristR", "HandR"],
	["HipL", "ThighL", "KneeL", "ShinL", "AnkleL", "FootL"],
	["HipR", "ThighR", "KneeR", "ShinR", "AnkleR", "FootR"],
]
## Partes que NAO se soltam.
const CORE := ["Chest", "Abdomen", "Pelvis"]
## Partes do braco: perder uma NAO derruba o inimigo.
const ARM_PREFIXES := ["Shoulder", "UpperArm", "Elbow", "Forearm", "Wrist", "Hand"]

## Particulas de sangue (effects/blood.tscn) e mancha no chao/parede (effects/blood_stain.tscn).
@export var blood_scene: PackedScene
@export var stain_scene: PackedScene
## Pedacinhos que voam quando a cabeca explode (effects/gib.tscn).
@export var gib_scene: PackedScene
@export var head_gibs := 16
## Maximo de manchas na cena; passando disso as mais antigas somem.
@export var max_stains := 150
## Forca do empurrao que derruba o inimigo.
@export var topple_torque := 100.0
@export var topple_push := 40.0
## Forca com que o pedaco destruido e arremessado.
@export var debris_impulse := 6.0

var _hp := PART_HP.duplicate()
var _fallen := false
var _children := _build_children()

## O que sai junto com cada parte, montado a partir de CHAINS.
func _build_children() -> Dictionary:
	var result := {}
	for chain: Array in CHAINS:
		for i in chain.size():
			result[chain[i]] = chain.slice(i + 1)
	return result

## Chamado pela arma. hit = resultado do raycast, dir = direcao do tiro.
func take_hit(hit: Dictionary, dir: Vector3, damage: float) -> void:
	# o raycast diz o indice da forma atingida; daqui sai o no da parte (ex: KneeL)
	var part := shape_owner_get_owner(shape_find_owner(hit.shape)) as Node3D
	if part == null or not _hp.has(str(part.name)):
		return # parte que ja foi destruida
	var part_name := str(part.name)
	var origin: Vector3 = hit.position + hit.normal * 0.05
	_spawn_blood(get_tree().current_scene, hit.position, hit.normal, 12)
	_splatter(origin, dir, hit.normal, 2, 1.0)
	_hp[part_name] -= damage
	if _hp[part_name] > 0.0:
		return
	_hp.erase(part_name)
	_spawn_blood(get_tree().current_scene, hit.position, hit.normal, 40) # estouro maior
	_splatter(origin, dir, hit.normal, 8, 1.8)
	if part_name == "Head":
		_explode_head(part, dir) # a cabeca nao se solta inteira: explode
	elif not CORE.has(part_name):
		_detach(part, part_name, dir)
	if not _is_arm(part_name):
		_fall(dir)

func _is_arm(part_name: String) -> bool:
	for prefix: String in ARM_PREFIXES:
		if part_name.begins_with(prefix):
			return true
	return false

## Tira a parte (e o que vem junto dela) do inimigo e a transforma num pedaco fisico solto.
func _detach(part: Node3D, part_name: String, dir: Vector3) -> void:
	var group: Array[Node3D] = [part]
	for child_name: String in _children.get(part_name, []):
		var child := get_node_or_null(child_name) as Node3D
		if child and _hp.has(child_name):
			group.append(child)
			_hp.erase(child_name)

	var debris := RigidBody3D.new()
	debris.mass = 8.0
	get_tree().current_scene.add_child(debris)
	debris.global_transform = part.global_transform
	for piece in group:
		piece.reparent(debris, true) # true = mantem a posicao no mundo
	# o pedaco arrancado continua jorrando sangue por um tempo enquanto voa
	_spawn_blood(debris, part.global_position, Vector3.UP, 30, 1.5)
	debris.apply_central_impulse(dir * debris_impulse + Vector3.UP * 3.0)
	debris.apply_torque_impulse(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 3.0)

## A cabeca EXPLODE: nuvem grande de sangue pra todos os lados, pedacinhos voando, manchas
## espalhadas em volta e o pescoco fica jorrando. A cabeca some (nao vira pedaco inteiro).
func _explode_head(head: Node3D, dir: Vector3) -> void:
	var pos := head.global_position
	var scene := get_tree().current_scene
	_spawn_blood(scene, pos, Vector3.UP, 150, 0.0, true)
	_spawn_blood(scene, pos, dir, 60, 0.0, true)
	_splatter(pos, dir, Vector3.UP, 28, 2.5, 6.0)
	if gib_scene:
		for i in head_gibs:
			var gib: RigidBody3D = gib_scene.instantiate()
			scene.add_child(gib)
			gib.global_position = pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), randf_range(-0.1, 0.1))
			var spray := Vector3(randf_range(-1, 1), randf_range(0.2, 1.2), randf_range(-1, 1)).normalized()
			gib.apply_central_impulse((spray * randf_range(2.0, 6.0) + dir * 2.0) * gib.mass)
	head.queue_free()
	# o pescoco que sobrou jorra sangue por um tempo
	var neck := get_node_or_null("Neck") as Node3D
	if neck:
		_spawn_blood(self, neck.global_position, Vector3.UP, 40, 3.0)

## Cria um respingo de sangue. spurt_time > 0 = jorra por esse tempo (ver blood.gd).
## wide = estouro pra todos os lados e mais forte (cabeca explodindo).
func _spawn_blood(parent: Node, pos: Vector3, direction: Vector3, amount: int, spurt_time := 0.0, wide := false) -> void:
	if blood_scene == null:
		return
	var blood: Blood = blood_scene.instantiate()
	blood.amount = amount
	blood.direction = direction
	blood.spurt_time = spurt_time
	if wide:
		blood.spread = 180.0
		blood.initial_velocity_min = 3.0
		blood.initial_velocity_max = 9.0
		blood.lifetime = 1.0
	parent.add_child(blood)
	blood.global_position = pos

## Joga manchas de sangue no chao e na parede perto do tiro: lanca raios em varias direcoes
## (pra frente, de volta pra quem atirou e pra baixo, que e o mais comum) e, onde o raio
## acerta o cenario (StaticBody3D), cola uma mancha.
func _splatter(origin: Vector3, dir: Vector3, normal: Vector3, count: int, size_scale: float, reach := 4.0) -> void:
	if stain_scene == null:
		return
	var space := get_world_3d().direct_space_state
	var bases: Array[Vector3] = [dir, normal, Vector3.DOWN, Vector3.DOWN]
	for i in count:
		var jitter := Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)) * 0.6
		var base: Vector3 = bases.pick_random() # pick_random devolve Variant, entao o tipo e declarado
		var d := (base + jitter).normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + d * reach, 1)
		query.exclude = [get_rid()]
		var result := space.intersect_ray(query)
		# so o cenario recebe mancha (nao pedacos soltos do corpo, que se mexem)
		if result.is_empty() or not (result.collider is StaticBody3D):
			continue
		_place_stain(result.position, result.normal, randf_range(0.3, 0.7) * size_scale)

func _place_stain(pos: Vector3, normal: Vector3, stain_size: float) -> void:
	var stains := get_tree().get_nodes_in_group("blood_stain")
	if stains.size() >= max_stains:
		stains[0].queue_free()
	var stain: Decal = stain_scene.instantiate()
	stain.size = Vector3(stain_size, 0.4, stain_size)
	get_tree().current_scene.add_child(stain)
	# o Decal projeta no sentido -Y: alinha o +Y dele com a normal da superficie
	var basis := Basis(Quaternion(Vector3.UP, normal)) if normal.dot(Vector3.DOWN) < 0.999 else Basis(Vector3.RIGHT, PI)
	basis = basis.rotated(normal, randf() * TAU) # giro aleatorio, as manchas nao ficam iguais
	stain.global_transform = Transform3D(basis, pos)

## Descongela o corpo e o empurra pra tombar na direcao do tiro.
func _fall(dir: Vector3) -> void:
	if _fallen:
		return
	_fallen = true
	var flat := Vector3(dir.x, 0.0, dir.z).normalized()
	freeze = false
	sleeping = false
	# girar em volta de (cima x direcao) inclina o topo do corpo pra direcao do tiro
	apply_torque_impulse(Vector3.UP.cross(flat) * topple_torque)
	apply_central_impulse(flat * topple_push)
