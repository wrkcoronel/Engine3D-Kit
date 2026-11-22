extends TestCase


func test_rig_is_found_by_group_and_not_ready_until_it_has_a_body() -> void:
	var rig := PlayerRig.new()
	spawn(rig)
	assert_eq(PlayerRig.find(tree), rig, "achado pelo grupo")
	assert_true(not rig.is_ready(), "sem corpo ainda")
	rig.body = CharacterBody3D.new()
	assert_true(rig.is_ready(), "com corpo")
	rig.body.free()


func test_held_item_anchor_is_found_by_group() -> void:
	var anchor := HeldItemAnchor.new()
	spawn(anchor)
	assert_eq(HeldItemAnchor.find(tree), anchor, "achado pelo grupo")
	assert_true(not anchor.has_item, "comeca sem item")


func test_find_or_create_makes_an_empty_rig_when_there_is_none() -> void:
	var parent := Node.new()
	spawn(parent)
	var rig := PlayerRig.find_or_create(tree, parent)
	assert_true(rig != null, "criou um vazio")
	assert_true(not rig.is_ready(), "sem corpo")
	assert_eq(PlayerRig.find_or_create(tree, parent), rig, "reusa o que ja existe")
