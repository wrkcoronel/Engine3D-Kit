class_name MotelConstants
extends RefCounted

const FLOOR_HEIGHT := 3.0
const SLAB_THICKNESS := 0.25
const STORY_STEP := 3.25
const ROOF_BOTTOM_Y := 6.25
const ROOF_TOP_Y := 6.65
const PARAPET_TOP_Y := 7.05
const WALL_THICKNESS := 0.25

const ROOM_WIDTH := 4.6
const ROOM_DEPTH := 6.4
const WALKWAY_WIDTH := 2.2
const RAILING_HEIGHT := 1.05
const COLUMN_SIZE := 0.22

const MAIN_WING_BACK_Z := -16.4
const MAIN_WING_FRONT_Z := -10.0
const MAIN_WALKWAY_FRONT_Z := -7.8
const MAIN_WING_START_X := -12.0
const MAIN_ROOM_COUNT := 5
const OPEN_ROOM_INDEX := 2

const WEST_WING_OUTER_X := -18.4
const WEST_WING_FRONT_X := -12.0
const WEST_WALKWAY_FRONT_X := -9.8
const WEST_WING_START_Z := -7.8
const WEST_ROOM_COUNT := 3
const OPEN_WEST_ROOM_INDEX := 1

const RECEPTION_START_X := 11.0
const RECEPTION_END_X := 17.4
const RECEPTION_FRONT_Z := -9.0
const RECEPTION_DOOR_WIDTH := 1.4
const RECEPTION_DOOR_HEIGHT := 2.3
const CANOPY_END_X := 23.4
const CANOPY_BACK_Z := -14.8
const CANOPY_BOTTOM_Y := 3.8
const CANOPY_TOP_Y := 4.15

const STAIR_START_Z := 6.0
const STAIR_END_Z := 11.6
const STAIR_STEP_COUNT := 14

const DOOR_WIDTH := 1.25
const DOOR_HEIGHT := 2.25
const WINDOW_WIDTH := 2.0
const WINDOW_BOTTOM_Y := 0.95
const WINDOW_TOP_Y := 2.2

const LOT_MIN_X := -10.5
const LOT_MAX_X := 25.0
const LOT_MIN_Z := -7.8
const LOT_MAX_Z := 18.0

const POOL_MIN_X := 9.5
const POOL_MAX_X := 17.5
const POOL_MIN_Z := 3.5
const POOL_MAX_Z := 13.5


static func main_room_start_x(room_index: int) -> float:
	return MAIN_WING_START_X + float(room_index) * ROOM_WIDTH


static func west_room_start_z(room_index: int) -> float:
	return WEST_WING_START_Z + float(room_index) * ROOM_WIDTH


static func story_floor_y(story_index: int) -> float:
	return float(story_index) * STORY_STEP


static func main_wing_end_x() -> float:
	return MAIN_WING_START_X + float(MAIN_ROOM_COUNT) * ROOM_WIDTH


static func west_wing_end_z() -> float:
	return WEST_WING_START_Z + float(WEST_ROOM_COUNT) * ROOM_WIDTH


static func is_main_room_open(story_index: int, room_index: int) -> bool:
	var valid_story := story_index == 0 or story_index == 1
	return valid_story and room_index == OPEN_ROOM_INDEX


static func is_west_room_open(story_index: int, room_index: int) -> bool:
	var valid_story := story_index == 0 or story_index == 1
	return valid_story and room_index == OPEN_WEST_ROOM_INDEX


static func main_room_number(story_index: int, room_index: int) -> String:
	var floor_base := (story_index + 1) * 100
	return str(floor_base + room_index + 1)


static func west_room_number(story_index: int, room_index: int) -> String:
	var floor_base := (story_index + 1) * 100
	return str(floor_base + MAIN_ROOM_COUNT + room_index + 1)
