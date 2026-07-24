extends Node2D

const WORLD_HALF := 16384.0
const MAX_SEGMENT_LENGTH := 280.0
const MIN_SEGMENT_LENGTH := 28.0
const BASE_TOTAL_HYPHA_CAPACITY := 1800.0
const ORGANIC_PER_LENGTH := 22.0
const DNA_ORGANIC_COST := 30.0
const DNA_MINERAL_COST := 1.0
const DNA_JOB_SECONDS := 180.0
const DNA_SPEED_BONUS_PER_NODE_LEVEL := 0.15
const CORE_ORGANIC_COST := 70.0
const CORE_MINERAL_COST := 6.0
const OFFLINE_CAP_SECONDS := 7200.0
const OFFLINE_MIN_SECONDS := 30.0
const OFFLINE_STEP_SECONDS := 5.0
const OFFLINE_BACTERIA_CAP_SECONDS := 600.0
const OFFLINE_HAZARD_CAP_SECONDS := 60.0
const OFFLINE_ORPHAN_CAP_SECONDS := 600.0
const SAVE_INTERVAL := 15.0
const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"
const UI_FONT_PATH := "res://assets/fonts/fusion-bold/fusion-bold-pixel-12px-proportional-zh_hans.ttf"
const SPLASH_LOGO_PATH := "res://assets/branding/splash-logo.png"
const CURSOR_TEXTURE_PATH := "res://assets/ui/cursor-green.svg"
const UI_FONT_SIZE := 12
const SPLASH_FADE_IN_SECONDS := 0.90
const SPLASH_HOLD_SECONDS := 1.10
const SPLASH_FADE_OUT_SECONDS := 0.90
const FEEDER_SENSE_RADIUS := 72.0
const FEEDER_RANGE_PER_LEVEL := 24.0
const MAX_FEEDER_RANGE_LEVEL := 5
const FEEDER_RANGE_UPGRADE_COSTS := [45.0, 75.0, 123.0, 203.0, 335.0]
const DIET_IDS := ["animal", "plant", "bacteria", "fungi"]
const DIET_NAMES := {"animal": "肉食性", "plant": "植食性", "bacteria": "细菌食性", "fungi": "真菌食性"}
const DIET_TARGETS := {"animal": "动物组织与小型动物宿主", "plant": "植物组织与植物宿主", "bacteria": "细菌群落", "fungi": "其他真菌与菌落"}
const DIET_EFFICIENCIES := [0.0, 0.20, 0.40, 0.60, 0.80, 1.00]
const DIET_LEVEL_COSTS := [2, 4, 7, 12]
const DIET_UNLOCK_BASE_COST := 3
const BACTERIA_COMPONENT_IDS := ["trap", "enzymes", "antibiotic"]
const BACTERIA_COMPONENT_NAMES := {"trap": "黏性捕食器", "enzymes": "胞外消化酶", "antibiotic": "抗生素分泌"}
const BACTERIA_COMPONENT_DESCRIPTIONS := {
	"trap": "生成细捕食丝，扩大细菌捕获距离",
	"enzymes": "提高捕获细菌转化为有机营养的速度",
	"antibiotic": "压低邻近细菌的吸收与分裂速度"
}
const BACTERIA_COMPONENT_COSTS := {
	"trap": [3, 6, 12],
	"enzymes": [4, 8, 16],
	"antibiotic": [5, 10, 20]
}
const STRUCTURE_IDS := ["branching", "elongation", "feeders", "growth"]
const STRUCTURE_NAMES := {"branching": "菌丝分枝", "elongation": "顶端延伸", "feeders": "吸收网络", "growth": "生长代谢"}
const STRUCTURE_DESCRIPTIONS := {
	"branching": "提高每个孢子核心可维持的主菌丝总长度",
	"elongation": "提高一次操作能够延伸的最大菌丝长度",
	"feeders": "增加同时连接营养点的细吸收菌丝数量",
	"growth": "缩短新生主菌丝完成生长所需的时间"
}
const STRUCTURE_LEVEL_COSTS := [2, 4, 7, 12]
const SURVIVAL_IDS := ["wall", "detox", "repair", "storage"]
const SURVIVAL_NAMES := {"wall": "细胞壁增厚", "detox": "解毒代谢", "repair": "修复酶系", "storage": "储备囊泡"}
const SURVIVAL_DESCRIPTIONS := {
	"wall": "所有核心最大生物量 +25.000",
	"detox": "受到的细菌毒素伤害 -15%",
	"repair": "自然恢复 +25%，储备释放 +20%",
	"storage": "每次购买的修复储备 +5.000"
}
const SURVIVAL_LEVEL_COSTS := [2, 4, 7, 12]
const FEEDER_ORGANIC_RATE := 0.100
const FEEDER_MINERAL_RATE := 0.030
const MAX_ACTIVE_FEEDERS := 48
const FEEDERS_PER_DISCOVERY := 2
const BACTERIA_ABSORB_RATE := FEEDER_ORGANIC_RATE / 20.0
const BACTERIA_ABSORB_RADIUS := 52.0
const BACTERIA_RESOURCE_SCAN_SECONDS := 5.0
const BACTERIA_DIVISION_NUTRIENT := 0.100
const BACTERIA_DIVISION_COOLDOWN := 12.0
const BACTERIA_UPDATE_INTERVAL := 0.250
const BACTERIA_CONTACT_SCAN_SECONDS := 3.0
const BACTERIA_PREDATION_RATE := 0.050
const BACTERIA_PREDATION_RADIUS := 14.0
const MAX_BACTERIA := 420
const RESOURCE_GRID_CELL_SIZE := 128.0
const EXPLORATION_CELL_SIZE := 512.0
const EXPLORATION_GRID_SIDE := 64
const CORE_REVEAL_RADIUS := 420.0
const HYPHA_REVEAL_RADIUS := 260.0
const UNIT_REVEAL_RADIUS := 300.0
const SCOUT_REVEAL_RADIUS := 760.0
const SCOUT_OPERATING_RADIUS := 1800.0
const SCOUT_SEARCH_RADIUS := 2200.0
const SCOUT_UPGRADE_IDS := ["vision", "speed"]
const SCOUT_UPGRADE_NAMES := {"vision": "感知网络", "speed": "鞭毛运动"}
const SCOUT_UPGRADE_COSTS := [2, 4, 7, 12]
const MAX_SCOUT_UPGRADE_LEVEL := 4
const GOALS_PER_PAGE := 5
const CORE_MAX_BIOMASS := 100.0
const CORE_REPAIR_AMOUNT := 20.0
const CORE_REPAIR_ORGANIC_COST := 10.0
const CORE_PASSIVE_RECOVERY_RATE := 0.005
const CORE_REPAIR_RECOVERY_RATE := 0.080
const BACTERIA_TOXIN_RADIUS := 48.0
const BACTERIA_TOXIN_DAMAGE_RATE := 0.004
const ECOLOGY_FIRST_EVENT_MIN := 180.0
const ECOLOGY_FIRST_EVENT_MAX := 240.0
const ECOLOGY_EVENT_INTERVAL_MIN := 360.0
const ECOLOGY_EVENT_INTERVAL_MAX := 600.0
const ECOLOGY_EVENT_WARNING_SECONDS := 45.0
const ECOLOGY_BLOOM_ACTIVE_SECONDS := 120.0
const ECOLOGY_TOXIN_ACTIVE_SECONDS := 75.0
const ECOLOGY_BLOOM_RADIUS := 120.0
const ECOLOGY_TOXIN_ZONE_RADIUS := 105.0
const ECOLOGY_BLOOM_SPAWN_COUNT := 16
const ECOLOGY_TOXIN_DAMAGE_RATE := 0.045
const ECOLOGY_BLOOM_TOXIN_MULTIPLIER := 1.15
const CORE_MAX_TOXIN_DAMAGE_RATE := 0.35
const ORPHAN_HYPHA_DECAY_SECONDS := 180.0
const ORPHAN_RESCUE_DISTANCE := 18.0
const BARRACKS_ORGANIC_COST := 95.0
const BARRACKS_MINERAL_COST := 8.0
const BARRACKS_DNA_COST := 2
const EXPEDITION_SPORE_ORGANIC_COST := 8.0
const EXPEDITION_SPORE_MINERAL_COST := 0.250
const EXPEDITION_SPORE_BUILD_SECONDS := 30.0
const MAX_EXPEDITION_SPORES := 64
const EXPEDITION_MOVE_SPEED := 45.0
const EXPEDITION_CARGO_CAPACITY := 3.0
const EXPEDITION_GATHER_RATE := 0.040
const EXPEDITION_ATTACK_RATE := 0.060
const EXPEDITION_SEARCH_RADIUS := 260.0
const EXPEDITION_OPERATING_RADIUS := 280.0
const EXPEDITION_ARRIVAL_DISTANCE := 10.0
const BARRACK_UNIT_IDS := ["forager", "carrier", "chelator", "scout"]
const BARRACK_UNIT_NAMES := {"forager": "游猎孢子", "carrier": "囊载孢子", "chelator": "螯合孢子", "scout": "嗅营孢子", "lytic": "裂菌孢子"}
const BARRACK_UNIT_DESCRIPTIONS := {
	"forager": "通用采集与自卫单位",
	"carrier": "低速、大容量有机营养运输",
	"chelator": "专门寻找并运输矿物离子",
	"scout": "高速移动并自动揭开周围探索黑幕",
	"lytic": "细菌食性专属的高速裂菌单位"
}
const BARRACK_UNIT_UNLOCK_COSTS := {"carrier": 3, "chelator": 4, "scout": 5}
const UNIT_ORGANIC_COSTS := {"forager": 8.0, "carrier": 14.0, "chelator": 10.0, "scout": 6.0, "lytic": 12.0}
const UNIT_MINERAL_COSTS := {"forager": 0.250, "carrier": 0.500, "chelator": 1.000, "scout": 0.400, "lytic": 0.750}
const UNIT_BUILD_SECONDS := {"forager": 30.0, "carrier": 50.0, "chelator": 42.0, "scout": 24.0, "lytic": 40.0}
const DIET_SPECIAL_UNITS := {
	"animal": [
		{"id": "animal_attach", "name": "捕食附着体", "desc": "附着动物组织并建立消化点", "available": false, "requirement": "等待小型动物生态"},
		{"id": "animal_pierce", "name": "穿刺孢子", "desc": "攻击动物表层与运动结构", "available": false, "requirement": "等待小型动物生态"},
		{"id": "animal_digest", "name": "消化囊体", "desc": "范围分解动物性有机物", "available": false, "requirement": "等待小型动物生态"}
	],
	"plant": [
		{"id": "plant_fiber", "name": "纤维分解体", "desc": "针对植物细胞壁的采食单位", "available": false, "requirement": "等待植物组织生态"},
		{"id": "plant_attach", "name": "表皮附着体", "desc": "固定于植物表面建立侵入点", "available": false, "requirement": "等待植物组织生态"},
		{"id": "plant_vessel", "name": "导管扩散体", "desc": "沿植物输导结构进行扩张", "available": false, "requirement": "等待植物组织生态"}
	],
	"bacteria": [
		{"id": "lytic", "name": "裂菌孢子", "desc": "高速追猎细菌，击杀后携带营养返巢", "available": true, "cost": 4},
		{"id": "suppressor", "name": "抑菌囊体", "desc": "部署范围抑菌区，降低吸收与分裂", "available": false, "requirement": "等待范围部署系统"},
		{"id": "disperser", "name": "溶菌散播体", "desc": "对密集细菌群释放范围裂解酶", "available": false, "requirement": "等待范围部署系统"}
	],
	"fungi": [
		{"id": "coil", "name": "缠丝猎手", "desc": "缠绕并切断敌方真菌菌丝", "available": false, "requirement": "等待敌方真菌菌落"},
		{"id": "piercer", "name": "穿壁孢子", "desc": "附着敌方核心并蓄力穿透", "available": false, "requirement": "等待敌方真菌菌落"},
		{"id": "antifungal", "name": "抗真菌囊体", "desc": "抑制敌方生长、修复与菌丝重连", "available": false, "requirement": "等待敌方真菌菌落"}
	]
}

const COLOR_BG := Color("07152b")
const COLOR_BG_2 := Color("0b2037")
const COLOR_HYPHA := Color("b9f2cf")
const COLOR_HYPHA_GLOW := Color(0.43, 0.92, 0.69, 0.18)
const COLOR_CORE := Color("dff7d8")
const COLOR_ORGANIC := Color("f3b562")
const COLOR_MINERAL := Color("aa84ec")
const COLOR_WATER := Color("58b8df")
const COLOR_BACTERIA := Color("ff7e9f")
const COLOR_TEXT := Color("d7ebe6")
const COLOR_MUTED := Color("8ba9ad")
const COLOR_PANEL := Color(0.025, 0.075, 0.12, 0.9)
const COLOR_BORDER := Color(0.32, 0.67, 0.63, 0.48)

var rng := RandomNumberGenerator.new()
var resources: Array = []
var resource_grid: Dictionary = {}
var resource_hotspots: Array = []
var water_motes: Array = []
var substrate_marks: Array = []
var cores: Array = []
var segments: Array = []
var feeders: Array = []
var bacteria: Array = []
var expedition_units: Array = []
var next_expedition_id := 1
var explored_cells: Dictionary = {}
var discovered_hotspots: Dictionary = {}
var last_discovery_scan_cell_count := -1

var organic := 220.0
var mineral := 24.0
var dna := 0
var camera_center := Vector2.ZERO
var camera_zoom := 0.65
var sim_speed := 1.0
var sim_time := 0.0
var absorb_clock := 0.0
var bacteria_update_clock := 0.0
var expedition_update_clock := 0.0
var save_clock := 0.0
var game_over := false

var selected_core := -1
var selected_tip := Vector2.ZERO
var selected_tip_valid := false
var selected_tip_core := -1
var mode := "normal"
var show_status := false
var menu_anim := 0.0
var upgrade_open := false
var upgrade_tab := 0
var upgrade_core_id := 0
var diet_detail_id := ""
var diet_detail_tab := 0
var goals_open := false
var goal_page := 0
var dragging := false
var drag_button := 0
var left_selecting := false
var left_dragged := false
var selection_start := Vector2.ZERO
var selection_current := Vector2.ZERO
var right_press_pos := Vector2.ZERO
var right_dragged := false
var selected_expedition_ids: Array = []
var toast_text := ""
var toast_time := 0.0
var last_mouse := Vector2.ZERO
var autosave_enabled := true
var save_path := SAVE_PATH
var diet_order: Array = []
var diet_levels := {"animal": 0, "plant": 0, "bacteria": 0, "fungi": 0}
var bacteria_components := {"trap": 0, "enzymes": 0, "antibiotic": 0}
var structure_levels := {"branching": 0, "elongation": 0, "feeders": 0, "growth": 0}
var survival_levels := {"wall": 0, "detox": 0, "repair": 0, "storage": 0}
var lifetime_organic_absorbed := 0.0
var lifetime_mineral_absorbed := 0.0
var lifetime_dna_produced := 0
var lifetime_bacteria_births := 0
var lifetime_bacteria_consumed := 0
var lifetime_expedition_organic_returned := 0.0
var lifetime_expedition_mineral_returned := 0.0
var lifetime_expedition_bacteria_killed := 0
var goals_claimed := {}
var barracks_unit_unlocks := {"forager": true, "carrier": false, "chelator": false, "scout": false}
var diet_unit_unlocks := {"lytic": false}
var scout_upgrade_levels := {"vision": 0, "speed": 0}
var splash_active := true
var splash_time := 0.0
var main_menu_active := true
var main_menu_page := "main"
var main_menu_has_save := false
var game_started := false
var settings_fullscreen := false
var settings_pixel_cursor := true
var discovery_banner_title := ""
var discovery_banner_detail := ""
var discovery_banner_time := 0.0
var offline_report_open := false
var offline_report: Dictionary = {}
var offline_simulating := false
var ecology_events: Array = []
var next_ecology_event_id := 1
var ecology_event_countdown := ECOLOGY_FIRST_EVENT_MAX
var lifetime_ecology_events_seen := 0
var lifetime_ecology_events_contained := 0
var ecology_banner_title := ""
var ecology_banner_detail := ""
var ecology_banner_time := 0.0

var fallback_font: Font
var splash_logo: Texture2D
var cursor_texture: Texture2D


func _ready() -> void:
	fallback_font = ThemeDB.fallback_font
	var bundled_font = load(UI_FONT_PATH)
	if bundled_font is FontFile:
		var pixel_font: FontFile = bundled_font.duplicate()
		pixel_font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		pixel_font.hinting = TextServer.HINTING_NONE
		pixel_font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		pixel_font.generate_mipmaps = false
		fallback_font = pixel_font
	var bundled_logo = load(SPLASH_LOGO_PATH)
	if bundled_logo is Texture2D:
		splash_logo = bundled_logo
	_load_settings()
	var bundled_cursor = load(CURSOR_TEXTURE_PATH)
	if bundled_cursor is Texture2D:
		cursor_texture = bundled_cursor
	_apply_settings()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	rng.seed = 0xF00D47
	_generate_world()
	main_menu_has_save = FileAccess.file_exists(save_path)
	set_process(true)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if game_started:
			_save_game()
		get_tree().quit()


func _generate_world() -> void:
	resources.clear()
	resource_grid.clear()
	bacteria.clear()
	resource_hotspots.clear()
	water_motes.clear()
	substrate_marks.clear()
	# 少量背景资源用于探索；主要资源来自空间聚集，不再均匀铺满地图。
	for i in range(320):
		_add_resource(_random_world_point(80.0), 0, rng.randf_range(7.0, 16.0))
	for i in range(64):
		_add_resource(_random_world_point(80.0), 1, rng.randf_range(2.0, 5.0))
	# 普通有机营养斑块。
	for i in range(48):
		var center := _random_world_point(380.0)
		_scatter_cluster(center, rng.randi_range(24, 46), rng.randf_range(65.0, 145.0), 0, 8.0, 21.0, false)
	# 普通矿物团簇更少、更紧密。
	for i in range(26):
		var center := _random_world_point(380.0)
		_scatter_cluster(center, rng.randi_range(8, 16), rng.randf_range(38.0, 82.0), 1, 2.0, 6.0, false)
	# 少数异常富集区：在主视野和小地图上都应明显形成热点。
	var anomaly_specs := [
		[Vector2(360, -90), 0, 88, 118.0],
		[Vector2(-300, 320), 1, 30, 72.0],
		[Vector2(-4200, 3100), 0, 104, 165.0],
		[Vector2(6400, -5100), 0, 92, 142.0],
		[Vector2(10500, 7600), 0, 116, 178.0],
		[Vector2(-11800, -6800), 0, 96, 150.0],
		[Vector2(5200, 4800), 1, 38, 88.0],
		[Vector2(-7600, 9200), 1, 34, 82.0],
		[Vector2(11200, -9800), 1, 42, 96.0]
	]
	for spec in anomaly_specs:
		_scatter_cluster(spec[0], int(spec[2]), float(spec[3]), int(spec[1]), 12.0 if int(spec[1]) == 0 else 3.0, 30.0 if int(spec[1]) == 0 else 8.0, true)
	_seed_bacteria()
	for i in range(1450):
		water_motes.append(_random_world_point(30.0))
	for i in range(1250):
		substrate_marks.append({
			"pos": _random_world_point(30.0),
			"size": rng.randi_range(1, 3),
			"alpha": rng.randf_range(0.04, 0.12)
		})


func _random_world_point(margin: float) -> Vector2:
	var radius := sqrt(rng.randf()) * maxf(1.0, WORLD_HALF - margin)
	var angle := rng.randf_range(0.0, TAU)
	return Vector2(cos(angle), sin(angle)) * radius


func _add_resource(pos: Vector2, kind: int, amount: float) -> void:
	var max_radius := WORLD_HALF - 20.0
	if pos.length() > max_radius:
		pos = pos.normalized() * max_radius
	var resource_id := resources.size()
	resources.append({
		"id": resource_id,
		"pos": pos,
		"kind": kind,
		"amount": amount,
		"initial_amount": amount,
		"alive": true,
		"phase": rng.randf_range(0.0, TAU)
	})
	var cell := _resource_cell(pos)
	if not resource_grid.has(cell):
		resource_grid[cell] = []
	(resource_grid[cell] as Array).append(resource_id)


func _scatter_cluster(center: Vector2, count: int, spread: float, kind: int, amount_min: float, amount_max: float, anomalous: bool) -> void:
	var hotspot_id := "anomaly_%d_%d_%d" % [kind, roundi(center.x), roundi(center.y)] if anomalous else ""
	resource_hotspots.append({"id": hotspot_id, "pos": center, "radius": spread, "kind": kind, "anomalous": anomalous})
	for i in range(count):
		var angle := rng.randf_range(0.0, TAU)
		# 平方分布让中心更密，同时保留少数向外散开的资源点。
		var distance := pow(rng.randf(), 1.65) * spread
		var jitter := Vector2(cos(angle), sin(angle)) * distance
		_add_resource(center + jitter, kind, rng.randf_range(amount_min, amount_max))


func _seed_bacteria() -> void:
	# 静止细菌优先出现在有机富集区，形成可观察但稀疏的初始菌落。
	var colony_specs := [
		[Vector2(350, -88), 12, 34.0],
		[Vector2(-4190, 3090), 9, 42.0],
		[Vector2(6380, -5070), 8, 38.0],
		[Vector2(10480, 7580), 8, 44.0],
		[Vector2(-11780, -6780), 7, 40.0]
	]
	for spec in colony_specs:
		var center: Vector2 = spec[0]
		for i in range(int(spec[1])):
			var angle := rng.randf_range(0.0, TAU)
			var distance := sqrt(rng.randf()) * float(spec[2])
			bacteria.append(_make_bacterium(center + Vector2.from_angle(angle) * distance))


func _make_bacterium(pos: Vector2) -> Dictionary:
	var max_radius := WORLD_HALF - 20.0
	if pos.length() > max_radius:
		pos = pos.normalized() * max_radius
	return {
		"pos": pos,
		"stored": rng.randf_range(0.0, BACTERIA_DIVISION_NUTRIENT * 0.55),
		"cooldown": rng.randf_range(0.0, BACTERIA_DIVISION_COOLDOWN),
		"biomass": 1.0,
		"resource_id": -1,
		"seek_cooldown": 0.0,
		"contact_cooldown": rng.randf_range(0.0, BACTERIA_CONTACT_SCAN_SECONDS),
		"in_contact": false,
		"suppressed": false,
		"colony_distance": INF,
		"contact_point": Vector2.ZERO,
		"event_id": -1,
		"strain": "normal",
		"phase": rng.randf_range(0.0, TAU)
	}


func _make_core(pos: Vector2, kind: String = "normal") -> Dictionary:
	var maximum := _core_max_biomass_value()
	return {
		"pos": pos,
		"radius": 19.0,
		"jobs": [],
		"spore_jobs": [],
		"production_unit": "forager",
		"kind": kind,
		"feeder_range_level": 0,
		"biomass": maximum,
		"max_biomass": maximum,
		"alive": true,
		"toxin_pressure": 0.0,
		"repair_reserve": 0.0,
		"reveal_cell": -1,
		"pulse": rng.randf_range(0.0, TAU)
	}


func _process(delta: float) -> void:
	if splash_active:
		splash_time += delta
		if splash_time >= SPLASH_FADE_IN_SECONDS + SPLASH_HOLD_SECONDS + SPLASH_FADE_OUT_SECONDS:
			splash_active = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		queue_redraw()
		return
	if main_menu_active:
		queue_redraw()
		return
	if offline_report_open:
		queue_redraw()
		return
	_handle_camera_keys(delta)
	if selected_core >= 0 or selected_tip_valid:
		menu_anim = minf(1.0, menu_anim + delta * 4.8)
	else:
		menu_anim = 0.0
	var sim_delta := delta * sim_speed
	sim_time += sim_delta
	_update_growth(sim_delta)
	_update_dna_jobs(sim_delta)
	_update_barracks_jobs(sim_delta)
	_update_feeders(sim_delta)
	_update_ecology_events(sim_delta)
	expedition_update_clock += sim_delta
	if expedition_update_clock >= 0.10:
		var expedition_step := expedition_update_clock
		expedition_update_clock = 0.0
		_update_expedition_units(expedition_step)
	bacteria_update_clock += sim_delta
	if bacteria_update_clock >= BACTERIA_UPDATE_INTERVAL:
		var bacteria_step := bacteria_update_clock
		bacteria_update_clock = 0.0
		_update_bacteria(bacteria_step)
		_update_core_hazards(bacteria_step)
		_update_orphaned_segments(bacteria_step)
	# 自动细菌丝感知在加速时最高按10×扫描，避免60×反复遍历整张地图。
	absorb_clock += delta * minf(sim_speed, 10.0)
	while absorb_clock >= 2.0:
		absorb_clock -= 2.0
		_discover_feeders()
	save_clock += delta
	if autosave_enabled and save_clock >= SAVE_INTERVAL:
		save_clock = 0.0
		_save_game()
	if toast_time > 0.0:
		toast_time -= delta
	if discovery_banner_time > 0.0:
		discovery_banner_time -= delta
	if ecology_banner_time > 0.0:
		ecology_banner_time -= delta
	queue_redraw()


func _handle_camera_keys(delta: float) -> void:
	var direction := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if direction.length_squared() > 0.0:
		camera_center += direction * (430.0 / camera_zoom) * delta
		_clamp_camera()


func _update_growth(sim_delta: float) -> void:
	for segment in segments:
		if bool(segment.get("orphaned", false)) or not _is_core_alive(int(segment["core_id"])):
			continue
		if float(segment["growth"]) < 1.0:
			segment["growth"] = min(1.0, float(segment["growth"]) + sim_delta / _hypha_growth_seconds())


func _update_dna_jobs(sim_delta: float) -> void:
	for core_id in range(cores.size()):
		if not _is_core_alive(core_id):
			continue
		var core: Dictionary = cores[core_id]
		var remaining := sim_delta
		var jobs: Array = core["jobs"]
		while remaining > 0.0 and not jobs.is_empty():
			var job = jobs[0]
			var job_left := float(job.get("remaining", DNA_JOB_SECONDS)) if job is Dictionary else float(job)
			if job_left <= remaining:
				remaining -= job_left
				jobs.pop_front()
				dna += 1
				lifetime_dna_produced += 1
				toast("DNA +1　孢子核心完成了一次代谢记录", 3.0)
			else:
				if job is Dictionary:
					job["remaining"] = job_left - remaining
				else:
					jobs[0] = job_left - remaining
				remaining = 0.0


func _queue_expedition_spore(core_id: int) -> void:
	if not _is_core_alive(core_id) or String(cores[core_id].get("kind", "normal")) != "barracks":
		return
	if expedition_units.size() >= MAX_EXPEDITION_SPORES:
		toast("体外部队数量已达到 %d" % MAX_EXPEDITION_SPORES, 3.0)
		return
	var jobs: Array = cores[core_id].get("spore_jobs", [])
	if jobs.size() >= 10:
		toast("兵营生产队列已满", 3.0)
		return
	var unit_type := String(cores[core_id].get("production_unit", "forager"))
	if not _available_barracks_units().has(unit_type):
		unit_type = "forager"
		cores[core_id]["production_unit"] = unit_type
	var organic_cost := float(UNIT_ORGANIC_COSTS.get(unit_type, EXPEDITION_SPORE_ORGANIC_COST))
	var mineral_cost := float(UNIT_MINERAL_COSTS.get(unit_type, EXPEDITION_SPORE_MINERAL_COST))
	var build_seconds := float(UNIT_BUILD_SECONDS.get(unit_type, EXPEDITION_SPORE_BUILD_SECONDS))
	if organic < organic_cost or mineral < mineral_cost:
		toast("生产%s需要 %.3f 有机营养与 %.3f 矿物" % [BARRACK_UNIT_NAMES.get(unit_type, unit_type), organic_cost, mineral_cost], 3.0)
		return
	organic -= organic_cost
	mineral -= mineral_cost
	jobs.append({"remaining": build_seconds, "total": build_seconds, "unit_type": unit_type})
	cores[core_id]["spore_jobs"] = jobs
	toast("%s已进入生产队列（%d / 10）" % [BARRACK_UNIT_NAMES.get(unit_type, unit_type), jobs.size()], 3.0)


func _available_barracks_units() -> Array:
	var available: Array = []
	for unit_id in BARRACK_UNIT_IDS:
		if bool(barracks_unit_unlocks.get(unit_id, false)):
			available.append(unit_id)
	if int(diet_levels.get("bacteria", 0)) > 0 and bool(diet_unit_unlocks.get("lytic", false)):
		available.append("lytic")
	return available


func _cycle_barracks_unit(core_id: int) -> void:
	if not _is_core_alive(core_id) or String(cores[core_id].get("kind", "normal")) != "barracks":
		return
	var available := _available_barracks_units()
	if available.is_empty():
		return
	var current := String(cores[core_id].get("production_unit", "forager"))
	var index := available.find(current)
	cores[core_id]["production_unit"] = available[(index + 1) % available.size()]
	toast("兵营生产切换为：%s" % BARRACK_UNIT_NAMES.get(cores[core_id]["production_unit"], "未知单位"), 2.5)


func _update_barracks_jobs(sim_delta: float) -> void:
	for core_id in range(cores.size()):
		if not _is_core_alive(core_id) or String(cores[core_id].get("kind", "normal")) != "barracks":
			continue
		var jobs: Array = cores[core_id].get("spore_jobs", [])
		var remaining_time := sim_delta
		while remaining_time > 0.0 and not jobs.is_empty() and expedition_units.size() < MAX_EXPEDITION_SPORES:
			var job: Dictionary = jobs[0]
			var job_left := float(job.get("remaining", EXPEDITION_SPORE_BUILD_SECONDS))
			if job_left <= remaining_time:
				remaining_time -= job_left
				jobs.pop_front()
				_spawn_expedition_spore(core_id, String(job.get("unit_type", "forager")))
			else:
				job["remaining"] = job_left - remaining_time
				remaining_time = 0.0


func _spawn_expedition_spore(core_id: int, unit_type: String = "forager") -> void:
	if not _is_core_alive(core_id) or expedition_units.size() >= MAX_EXPEDITION_SPORES:
		return
	var core_pos: Vector2 = cores[core_id]["pos"]
	var spawn_pos := core_pos + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(22.0, 34.0)
	expedition_units.append({
		"id": next_expedition_id,
		"unit_type": unit_type,
		"home_core_id": core_id,
		"pos": spawn_pos,
		"state": "idle",
		"target_kind": "",
		"target_pos": spawn_pos,
		"target_resource_id": -1,
		"cargo_organic": 0.0,
		"cargo_mineral": 0.0,
		"manual": false,
		"search_cooldown": rng.randf_range(0.0, 2.0),
		"command_until": 0.0,
		"reveal_cell": _exploration_key(_exploration_coords(spawn_pos)),
		"phase": rng.randf_range(0.0, TAU)
	})
	_reveal_exploration(spawn_pos, _scout_reveal_radius() if unit_type == "scout" else UNIT_REVEAL_RADIUS)
	next_expedition_id += 1


func _update_expedition_units(sim_delta: float, show_discovery_feedback: bool = true) -> void:
	var surviving: Array = []
	for unit in expedition_units:
		var home := _expedition_home_position(unit)
		if not home.is_finite():
			continue
		var state := String(unit.get("state", "idle"))
		if state == "returning":
			_move_expedition_unit(unit, home, sim_delta)
			if (unit["pos"] as Vector2).distance_to(home) <= EXPEDITION_ARRIVAL_DISTANCE:
				var returned_organic := float(unit.get("cargo_organic", 0.0))
				var returned_mineral := float(unit.get("cargo_mineral", 0.0))
				organic += returned_organic
				mineral += returned_mineral
				lifetime_expedition_organic_returned += returned_organic
				lifetime_expedition_mineral_returned += returned_mineral
				unit["cargo_organic"] = 0.0
				unit["cargo_mineral"] = 0.0
				unit["state"] = "idle"
				unit["manual"] = false
		elif state == "moving":
			var target: Vector2 = unit.get("target_pos", unit["pos"])
			_move_expedition_unit(unit, target, sim_delta)
			if (unit["pos"] as Vector2).distance_to(target) <= EXPEDITION_ARRIVAL_DISTANCE:
				var target_kind := String(unit.get("target_kind", ""))
				if target_kind == "resource":
					unit["state"] = "gathering"
				elif target_kind == "bacteria":
					unit["state"] = "attacking"
				else:
					unit["state"] = "guarding" if bool(unit.get("manual", false)) else "idle"
		elif state == "gathering":
			_update_expedition_gathering(unit, sim_delta)
		elif state == "attacking":
			_update_expedition_attack(unit, sim_delta)
		else:
			unit["search_cooldown"] = maxf(0.0, float(unit.get("search_cooldown", 0.0)) - sim_delta)
			if float(unit["search_cooldown"]) <= 0.0:
				_acquire_expedition_target(unit)
				unit["search_cooldown"] = _scout_search_cooldown() if String(unit.get("unit_type", "forager")) == "scout" else 2.0
		if float(unit.get("cargo_organic", 0.0)) + float(unit.get("cargo_mineral", 0.0)) >= _expedition_cargo_capacity(unit) - 0.0005:
			unit["state"] = "returning"
			unit["target_kind"] = "home"
		surviving.append(unit)
	expedition_units = surviving
	_prune_expedition_selection()
	_update_exploration(show_discovery_feedback)


func _move_expedition_unit(unit: Dictionary, target: Vector2, sim_delta: float) -> void:
	var speed := EXPEDITION_MOVE_SPEED
	match String(unit.get("unit_type", "forager")):
		"carrier": speed = 32.0
		"chelator": speed = 42.0
		"scout": speed = _scout_move_speed()
		"lytic": speed = 54.0
	unit["pos"] = (unit["pos"] as Vector2).move_toward(target, speed * sim_delta)


func _expedition_cargo_capacity(unit: Dictionary) -> float:
	match String(unit.get("unit_type", "forager")):
		"carrier": return 9.0
		"chelator", "lytic": return 1.5
	return EXPEDITION_CARGO_CAPACITY


func _update_expedition_gathering(unit: Dictionary, sim_delta: float) -> void:
	var resource := _resource_by_id(int(unit.get("target_resource_id", -1)))
	var expected_kind := 1 if String(unit.get("unit_type", "forager")) == "chelator" else 0
	if resource.is_empty() or not bool(resource.get("alive", false)) or int(resource.get("kind", -1)) != expected_kind:
		unit["state"] = "returning" if float(unit.get("cargo_organic", 0.0)) + float(unit.get("cargo_mineral", 0.0)) > 0.0 else "idle"
		return
	var carried := float(unit.get("cargo_organic", 0.0)) + float(unit.get("cargo_mineral", 0.0))
	var capacity_left := _expedition_cargo_capacity(unit) - carried
	var gather_rate := 0.018 if expected_kind == 1 else (0.060 if String(unit.get("unit_type", "forager")) == "carrier" else EXPEDITION_GATHER_RATE)
	var taken := minf(capacity_left, minf(float(resource["amount"]), gather_rate * sim_delta))
	resource["amount"] = maxf(0.0, float(resource["amount"]) - taken)
	if expected_kind == 1:
		unit["cargo_mineral"] = float(unit.get("cargo_mineral", 0.0)) + taken
	else:
		unit["cargo_organic"] = float(unit.get("cargo_organic", 0.0)) + taken
	if float(resource["amount"]) <= 0.0005:
		resource["amount"] = 0.0
		resource["alive"] = false
		unit["state"] = "returning"


func _update_expedition_attack(unit: Dictionary, sim_delta: float) -> void:
	if _diet_efficiency("bacteria") <= 0.0:
		unit["state"] = "guarding"
		return
	var target: Vector2 = unit.get("target_pos", unit["pos"])
	var index := _nearest_bacterium_index(target, 18.0)
	if index < 0:
		unit["state"] = "returning" if float(unit.get("cargo_organic", 0.0)) > 0.0 else "idle"
		return
	var bacterium: Dictionary = bacteria[index]
	if offline_simulating and int(bacterium.get("event_id", -1)) >= 0:
		unit["state"] = "idle"
		return
	var attack_rate := 0.150 if String(unit.get("unit_type", "forager")) == "lytic" else EXPEDITION_ATTACK_RATE
	var attack := minf(float(bacterium.get("biomass", 1.0)), attack_rate * _diet_efficiency("bacteria") * sim_delta)
	bacterium["biomass"] = float(bacterium.get("biomass", 1.0)) - attack
	unit["cargo_organic"] = minf(_expedition_cargo_capacity(unit), float(unit.get("cargo_organic", 0.0)) + attack)
	if float(bacterium["biomass"]) <= 0.0005:
		bacteria.remove_at(index)
		lifetime_bacteria_consumed += 1
		lifetime_expedition_bacteria_killed += 1
		unit["state"] = "returning" if float(unit["cargo_organic"]) > 0.0 else "idle"


func _acquire_expedition_target(unit: Dictionary) -> void:
	var pos: Vector2 = unit["pos"]
	var best_kind := ""
	var best_pos := pos
	var best_distance := INF
	var unit_type := String(unit.get("unit_type", "forager"))
	if unit_type == "scout":
		var scout_target := _nearest_unexplored_scout_target(pos)
		if scout_target.is_finite():
			unit["target_kind"] = "ground"
			unit["target_pos"] = scout_target
			unit["state"] = "moving"
		return
	var resource := _nearest_resource_kind(pos, EXPEDITION_SEARCH_RADIUS, 1 if unit_type == "chelator" else 0) if unit_type != "lytic" else {}
	if not resource.is_empty() and _distance_to_colony(resource["pos"]) <= EXPEDITION_OPERATING_RADIUS:
		best_kind = "resource"
		best_pos = resource["pos"]
		best_distance = pos.distance_squared_to(best_pos)
		unit["target_resource_id"] = int(resource["id"])
	if _diet_efficiency("bacteria") > 0.0 and unit_type != "chelator" and unit_type != "carrier":
		var bacteria_index := _nearest_bacterium_index(pos, EXPEDITION_SEARCH_RADIUS)
		if bacteria_index >= 0:
			var bacteria_pos: Vector2 = bacteria[bacteria_index]["pos"]
			var bacteria_distance := pos.distance_squared_to(bacteria_pos)
			if _distance_to_colony(bacteria_pos) <= EXPEDITION_OPERATING_RADIUS and bacteria_distance < best_distance:
				best_kind = "bacteria"
				best_pos = bacteria_pos
	if best_kind != "":
		unit["target_kind"] = best_kind
		unit["target_pos"] = best_pos
		unit["state"] = "moving"


func _nearest_resource_kind(pos: Vector2, radius: float, kind: int) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius * radius
	var center := _resource_cell(pos)
	var cell_radius := maxi(1, int(ceil(radius / RESOURCE_GRID_CELL_SIZE)))
	for cell_y in range(center.y - cell_radius, center.y + cell_radius + 1):
		for cell_x in range(center.x - cell_radius, center.x + cell_radius + 1):
			var ids: Array = resource_grid.get(Vector2i(cell_x, cell_y), [])
			for resource_id in ids:
				var resource := _resource_by_id(int(resource_id))
				if resource.is_empty() or not bool(resource.get("alive", false)) or int(resource.get("kind", -1)) != kind:
					continue
				if not _is_world_explored(resource["pos"]):
					continue
				var distance := pos.distance_squared_to(resource["pos"])
				if distance <= best_distance:
					best_distance = distance
					best = resource
	return best


func _nearest_bacterium_index(pos: Vector2, radius: float) -> int:
	var best_index := -1
	var best_distance := radius * radius
	for i in range(bacteria.size()):
		if offline_simulating and int(bacteria[i].get("event_id", -1)) >= 0:
			continue
		var distance := pos.distance_squared_to(bacteria[i]["pos"])
		if distance <= best_distance and _is_world_explored(bacteria[i]["pos"]):
			best_distance = distance
			best_index = i
	return best_index


func _exploration_coords(pos: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor((pos.x + WORLD_HALF) / EXPLORATION_CELL_SIZE)), 0, EXPLORATION_GRID_SIDE - 1),
		clampi(int(floor((pos.y + WORLD_HALF) / EXPLORATION_CELL_SIZE)), 0, EXPLORATION_GRID_SIDE - 1)
	)


func _exploration_key(cell: Vector2i) -> int:
	return cell.y * EXPLORATION_GRID_SIDE + cell.x


func _exploration_cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		-WORLD_HALF + (float(cell.x) + 0.5) * EXPLORATION_CELL_SIZE,
		-WORLD_HALF + (float(cell.y) + 0.5) * EXPLORATION_CELL_SIZE
	)


func _is_world_explored(pos: Vector2) -> bool:
	if pos.length() > WORLD_HALF:
		return false
	return explored_cells.has(_exploration_key(_exploration_coords(pos)))


func _reveal_exploration(pos: Vector2, radius: float) -> void:
	if not pos.is_finite():
		return
	var minimum := _exploration_coords(pos - Vector2.ONE * radius)
	var maximum := _exploration_coords(pos + Vector2.ONE * radius)
	var cell_padding := EXPLORATION_CELL_SIZE * 0.72
	for cell_y in range(minimum.y, maximum.y + 1):
		for cell_x in range(minimum.x, maximum.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			var center := _exploration_cell_center(cell)
			if center.length() > WORLD_HALF + cell_padding:
				continue
			if center.distance_to(pos) <= radius + cell_padding:
				explored_cells[_exploration_key(cell)] = true


func _update_exploration(show_discovery_feedback: bool = true) -> void:
	for core in cores:
		if bool(core.get("alive", true)):
			var core_cell := _exploration_key(_exploration_coords(core["pos"]))
			if int(core.get("reveal_cell", -1)) != core_cell:
				_reveal_exploration(core["pos"], CORE_REVEAL_RADIUS)
				core["reveal_cell"] = core_cell
	for segment in segments:
		var growth := clampf(float(segment.get("growth", 1.0)), 0.0, 1.0)
		var start: Vector2 = segment["a"]
		var finish: Vector2 = start.lerp(segment["b"], growth)
		var segment_cell := _exploration_key(_exploration_coords(finish))
		if int(segment.get("reveal_cell", -1)) == segment_cell:
			continue
		var sample_count := maxi(1, int(ceil(start.distance_to(finish) / HYPHA_REVEAL_RADIUS)))
		for sample in range(sample_count + 1):
			_reveal_exploration(start.lerp(finish, float(sample) / float(sample_count)), HYPHA_REVEAL_RADIUS)
		segment["reveal_cell"] = segment_cell
	for unit in expedition_units:
		var unit_cell := _exploration_key(_exploration_coords(unit["pos"]))
		if int(unit.get("reveal_cell", -1)) == unit_cell:
			continue
		var reveal_radius := _scout_reveal_radius() if String(unit.get("unit_type", "forager")) == "scout" else UNIT_REVEAL_RADIUS
		_reveal_exploration(unit["pos"], reveal_radius)
		unit["reveal_cell"] = unit_cell
	if explored_cells.size() != last_discovery_scan_cell_count:
		_sync_hotspot_discoveries(show_discovery_feedback)
		last_discovery_scan_cell_count = explored_cells.size()


func _explored_fraction() -> float:
	var dish_cells := 0
	for cell_y in range(EXPLORATION_GRID_SIDE):
		for cell_x in range(EXPLORATION_GRID_SIDE):
			if _exploration_cell_center(Vector2i(cell_x, cell_y)).length() <= WORLD_HALF + EXPLORATION_CELL_SIZE * 0.72:
				dish_cells += 1
	return float(explored_cells.size()) / maxf(1.0, float(dish_cells))


func _hotspot_display_name(hotspot: Dictionary) -> String:
	if int(hotspot.get("kind", 0)) == 1:
		return "矿物离子结晶区"
	var nearby_bacteria := 0
	var center: Vector2 = hotspot["pos"]
	var scan_radius := float(hotspot.get("radius", 80.0)) + 90.0
	for bacterium in bacteria:
		if center.distance_to(bacterium["pos"]) <= scan_radius:
			nearby_bacteria += 1
			if nearby_bacteria >= 3:
				return "细菌增殖富集区"
	return "高浓度有机沉积"


func _sync_hotspot_discoveries(show_feedback: bool) -> int:
	var new_discoveries: Array[String] = []
	for hotspot in resource_hotspots:
		if not bool(hotspot.get("anomalous", false)):
			continue
		var hotspot_id := String(hotspot.get("id", ""))
		if hotspot_id == "" or discovered_hotspots.has(hotspot_id):
			continue
		if not _is_world_explored(hotspot["pos"]):
			continue
		discovered_hotspots[hotspot_id] = true
		new_discoveries.append(_hotspot_display_name(hotspot))
	if show_feedback and not new_discoveries.is_empty():
		discovery_banner_title = "发现新的培养区" if new_discoveries.size() == 1 else "同时发现 %d 处异常区" % new_discoveries.size()
		discovery_banner_detail = "、".join(new_discoveries.slice(0, mini(3, new_discoveries.size()))) + "　·　已永久标记"
		discovery_banner_time = 6.0
		toast("探索记录 +%d　可在目标面板查看奖励" % new_discoveries.size(), 4.0)
	return new_discoveries.size()


func _discovered_hotspot_count(kind: int = -1) -> int:
	var count := 0
	for hotspot in resource_hotspots:
		if not bool(hotspot.get("anomalous", false)):
			continue
		if kind >= 0 and int(hotspot.get("kind", -1)) != kind:
			continue
		if discovered_hotspots.has(String(hotspot.get("id", ""))):
			count += 1
	return count


func _scout_move_speed() -> float:
	return 82.0 * (1.0 + float(scout_upgrade_levels.get("speed", 0)) * 0.15)


func _scout_reveal_radius() -> float:
	return SCOUT_REVEAL_RADIUS * (1.0 + float(scout_upgrade_levels.get("vision", 0)) * 0.20)


func _scout_search_radius() -> float:
	return SCOUT_SEARCH_RADIUS * (1.0 + float(scout_upgrade_levels.get("vision", 0)) * 0.10)


func _scout_search_cooldown() -> float:
	return 2.0 / (1.0 + float(scout_upgrade_levels.get("vision", 0)) * 0.25)


func _expedition_operating_radius(unit: Dictionary) -> float:
	return SCOUT_OPERATING_RADIUS if String(unit.get("unit_type", "forager")) == "scout" else EXPEDITION_OPERATING_RADIUS


func _nearest_unexplored_scout_target(pos: Vector2) -> Vector2:
	var origin := _exploration_coords(pos)
	var search_radius := _scout_search_radius()
	var cell_range := int(ceil(search_radius / EXPLORATION_CELL_SIZE)) + 1
	var best := Vector2(INF, INF)
	var best_distance := INF
	for cell_y in range(maxi(0, origin.y - cell_range), mini(EXPLORATION_GRID_SIDE, origin.y + cell_range + 1)):
		for cell_x in range(maxi(0, origin.x - cell_range), mini(EXPLORATION_GRID_SIDE, origin.x + cell_range + 1)):
			var cell := Vector2i(cell_x, cell_y)
			if explored_cells.has(_exploration_key(cell)):
				continue
			var candidate := _exploration_cell_center(cell)
			var distance := pos.distance_squared_to(candidate)
			if candidate.length() > WORLD_HALF or distance > search_radius * search_radius:
				continue
			if _distance_to_colony(candidate) > SCOUT_OPERATING_RADIUS:
				continue
			if distance < best_distance:
				best_distance = distance
				best = candidate
	return best


func _expedition_home_position(unit: Dictionary) -> Vector2:
	var home_core_id := int(unit.get("home_core_id", -1))
	if _is_core_alive(home_core_id) and String(cores[home_core_id].get("kind", "normal")) == "barracks":
		return cores[home_core_id]["pos"]
	for core_id in range(cores.size()):
		if _is_core_alive(core_id) and String(cores[core_id].get("kind", "normal")) == "barracks":
			unit["home_core_id"] = core_id
			return cores[core_id]["pos"]
	for core_id in range(cores.size()):
		if _is_core_alive(core_id):
			return cores[core_id]["pos"]
	return Vector2(INF, INF)


func _prune_expedition_selection() -> void:
	var living_ids := {}
	for unit in expedition_units:
		living_ids[int(unit.get("id", -1))] = true
	var kept: Array = []
	for unit_id in selected_expedition_ids:
		if living_ids.has(int(unit_id)):
			kept.append(int(unit_id))
	selected_expedition_ids = kept


func _expedition_unit_at_screen(screen_pos: Vector2) -> int:
	var best_id := -1
	var best_distance := 12.0
	for unit in expedition_units:
		var distance := screen_pos.distance_to(world_to_screen(unit["pos"]))
		if distance <= best_distance:
			best_distance = distance
			best_id = int(unit.get("id", -1))
	return best_id


func _selection_rect(start_screen: Vector2, end_screen: Vector2) -> Rect2:
	var top_left := Vector2(minf(start_screen.x, end_screen.x), minf(start_screen.y, end_screen.y))
	var size := Vector2(absf(end_screen.x - start_screen.x), absf(end_screen.y - start_screen.y))
	return Rect2(top_left, size)


func _select_expedition_box(start_screen: Vector2, end_screen: Vector2) -> void:
	if game_over or upgrade_open or goals_open:
		return
	var selection_rect := _selection_rect(start_screen, end_screen)
	selected_expedition_ids.clear()
	for unit in expedition_units:
		if selection_rect.has_point(world_to_screen(unit["pos"])):
			selected_expedition_ids.append(int(unit.get("id", -1)))
	selected_core = -1
	selected_tip_valid = false
	show_status = false
	mode = "normal"
	if not selected_expedition_ids.is_empty():
		toast("已选中 %d 个体外单位" % selected_expedition_ids.size(), 1.8)


func _resource_at_world(world_pos: Vector2, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius * radius
	for resource in resources:
		if not bool(resource.get("alive", false)):
			continue
		if not _is_world_explored(resource["pos"]):
			continue
		var distance := world_pos.distance_squared_to(resource["pos"])
		if distance <= best_distance:
			best_distance = distance
			best = resource
	return best


func _clamp_expedition_command_target(world_pos: Vector2, operating_radius: float = EXPEDITION_OPERATING_RADIUS) -> Vector2:
	var source := _nearest_colony_source(world_pos)
	if int(source.get("core_id", -1)) < 0:
		return world_pos
	var colony_point: Vector2 = source["point"]
	var offset := world_pos - colony_point
	if offset.length() > operating_radius:
		return colony_point + offset.normalized() * operating_radius
	return world_pos


func _issue_expedition_command(screen_pos: Vector2) -> void:
	if game_over or upgrade_open or goals_open or selected_expedition_ids.is_empty():
		return
	var requested := screen_to_world(screen_pos)
	var hit_radius := clampf(12.0 / maxf(camera_zoom, 0.001), 12.0, 42.0)
	var target_kind := "ground"
	var requested_target := requested
	var resource_id := -1
	if _is_world_explored(requested):
		var bacterium_index := _nearest_bacterium_index(requested, hit_radius)
		var resource := _resource_at_world(requested, hit_radius)
		if bacterium_index >= 0:
			target_kind = "bacteria"
			requested_target = bacteria[bacterium_index]["pos"]
		elif not resource.is_empty():
			target_kind = "resource"
			requested_target = resource["pos"]
			resource_id = int(resource["id"])
	var commanded := 0
	for unit in expedition_units:
		if not selected_expedition_ids.has(int(unit.get("id", -1))):
			continue
		var target := _clamp_expedition_command_target(requested_target, _expedition_operating_radius(unit))
		var unit_target_kind := target_kind
		var unit_resource_id := resource_id
		if target.distance_to(requested_target) > 0.01:
			unit_target_kind = "ground"
			unit_resource_id = -1
		elif String(unit.get("unit_type", "forager")) == "scout" and (target_kind == "resource" or target_kind == "bacteria"):
			unit_target_kind = "ground"
			unit_resource_id = -1
		unit["manual"] = true
		unit["target_kind"] = unit_target_kind
		unit["target_pos"] = target
		unit["target_resource_id"] = unit_resource_id
		unit["state"] = "moving"
		unit["command_until"] = sim_time + 3.0
		commanded += 1
	if commanded > 0:
		toast("已向 %d 个体外单位下达指令" % commanded, 1.8)


func _discover_feeders() -> void:
	if feeders.size() >= _active_feeder_capacity():
		return
	var connected := {}
	for feeder in feeders:
		connected[int(feeder["resource_id"])] = true
	var organic_candidates: Array = []
	var mineral_candidates: Array = []
	for resource in resources:
		if not bool(resource["alive"]) or float(resource["amount"]) <= 0.0005:
			continue
		var resource_id := int(resource["id"])
		if connected.has(resource_id):
			continue
		var p: Vector2 = resource["pos"]
		var source := _nearest_colony_source(p)
		var core_id := int(source["core_id"])
		if core_id < 0:
			continue
		var distance := float(source["distance"])
		if distance <= _feeder_range_for_core(core_id):
			var candidate := {"resource_id": resource_id, "a": source["point"], "b": p, "distance": distance, "core_id": core_id, "kind": int(resource["kind"])}
			if int(resource["kind"]) == 0:
				organic_candidates.append(candidate)
			else:
				mineral_candidates.append(candidate)
	organic_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["distance"]) < float(right["distance"]))
	mineral_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["distance"]) < float(right["distance"]))
	var selected: Array = []
	# 每轮为两类资源分别预留一个名额，避免有机富集区长期挤占矿物连接。
	if not organic_candidates.is_empty():
		selected.append(organic_candidates.pop_front())
	if not mineral_candidates.is_empty():
		selected.append(mineral_candidates.pop_front())
	var remaining_candidates := organic_candidates + mineral_candidates
	remaining_candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["distance"]) < float(right["distance"]))
	while selected.size() < FEEDERS_PER_DISCOVERY and not remaining_candidates.is_empty():
		selected.append(remaining_candidates.pop_front())
	var count := mini(selected.size(), _active_feeder_capacity() - feeders.size())
	for i in range(count):
		var candidate: Dictionary = selected[i]
		feeders.append({
			"resource_id": int(candidate["resource_id"]),
			"a": candidate["a"],
			"b": candidate["b"],
			"core_id": int(candidate["core_id"]),
			"growth": 0.0,
			"phase": rng.randf_range(0.0, TAU)
		})


func _update_feeders(sim_delta: float) -> void:
	var surviving: Array = []
	for feeder in feeders:
		if not _is_core_alive(int(feeder.get("core_id", -1))):
			continue
		var resource := _resource_by_id(int(feeder["resource_id"]))
		if resource.is_empty() or not bool(resource["alive"]):
			continue
		surviving.append(feeder)
		if float(feeder["growth"]) < 1.0:
			var length: float = (feeder["b"] as Vector2).distance_to(feeder["a"])
			var grow_seconds := maxf(16.0, length * 0.32)
			feeder["growth"] = minf(1.0, float(feeder["growth"]) + sim_delta / grow_seconds)
			continue
		var rate := FEEDER_ORGANIC_RATE if int(resource["kind"]) == 0 else FEEDER_MINERAL_RATE
		var taken := minf(float(resource["amount"]), rate * sim_delta)
		resource["amount"] = maxf(0.0, float(resource["amount"]) - taken)
		if int(resource["kind"]) == 0:
			organic += taken
			lifetime_organic_absorbed += taken
		else:
			mineral += taken
			lifetime_mineral_absorbed += taken
		if float(resource["amount"]) <= 0.0005:
			resource["amount"] = 0.0
			resource["alive"] = false
			surviving.erase(feeder)
	feeders = surviving


func _current_ecology_event() -> Dictionary:
	if ecology_events.is_empty():
		return {}
	return ecology_events[0]


func _ecology_events_enabled() -> bool:
	return not game_over and _living_core_count() > 0 and _diet_efficiency("bacteria") > 0.0


func _ecology_event_name(event_type: String) -> String:
	return "局部细菌暴发" if event_type == "bloom" else "代谢毒素区"


func _show_ecology_banner(title: String, detail: String, seconds: float = 6.0) -> void:
	ecology_banner_title = title
	ecology_banner_detail = detail
	ecology_banner_time = seconds


func _begin_ecology_event() -> void:
	if not ecology_events.is_empty() or not _ecology_events_enabled():
		return
	var living_core_ids: Array = []
	for core_id in range(cores.size()):
		if _is_core_alive(core_id):
			living_core_ids.append(core_id)
	if living_core_ids.is_empty():
		return
	var event_type := "bloom" if lifetime_ecology_events_seen % 2 == 0 else "toxin"
	var anchor_id := int(living_core_ids[lifetime_ecology_events_seen % living_core_ids.size()])
	var anchor: Vector2 = cores[anchor_id]["pos"]
	var distance := rng.randf_range(180.0, 195.0) if event_type == "bloom" else rng.randf_range(60.0, 85.0)
	var center := anchor + Vector2.from_angle(rng.randf_range(0.0, TAU)) * distance
	var maximum_radius := WORLD_HALF - ECOLOGY_BLOOM_RADIUS - 20.0
	if center.length() > maximum_radius:
		center = center.normalized() * maximum_radius
	var event := {
		"id": next_ecology_event_id,
		"type": event_type,
		"pos": center,
		"radius": ECOLOGY_BLOOM_RADIUS if event_type == "bloom" else ECOLOGY_TOXIN_ZONE_RADIUS,
		"phase": "warning",
		"remaining": ECOLOGY_EVENT_WARNING_SECONDS,
		"anchor_core_id": anchor_id,
		"spawned": 0
	}
	next_ecology_event_id += 1
	lifetime_ecology_events_seen += 1
	ecology_events = [event]
	_reveal_exploration(center, float(event["radius"]) + 48.0)
	_update_exploration(false)
	_show_ecology_banner("生态预警：%s" % _ecology_event_name(event_type), "点击右侧事件卡定位；准备裂菌孢子、抗生素或修复储备。", 7.0)


func _spawn_bloom_bacteria(event: Dictionary) -> int:
	var available := maxi(0, MAX_BACTERIA - bacteria.size())
	var spawn_count := mini(ECOLOGY_BLOOM_SPAWN_COUNT, available)
	for i in range(spawn_count):
		var angle := rng.randf_range(0.0, TAU)
		var distance := sqrt(rng.randf()) * float(event["radius"]) * 0.65
		var bacterium := _make_bacterium((event["pos"] as Vector2) + Vector2.from_angle(angle) * distance)
		bacterium["event_id"] = int(event["id"])
		bacterium["strain"] = "bloom"
		bacterium["stored"] = rng.randf_range(0.060, 0.080)
		bacterium["cooldown"] = rng.randf_range(4.0, 8.0)
		bacteria.append(bacterium)
	event["spawned"] = spawn_count
	return spawn_count


func _count_event_bacteria(event_id: int) -> int:
	var count := 0
	for bacterium in bacteria:
		if int(bacterium.get("event_id", -1)) == event_id:
			count += 1
	return count


func _release_event_bacteria(event_id: int) -> void:
	for bacterium in bacteria:
		if int(bacterium.get("event_id", -1)) == event_id:
			bacterium["event_id"] = -1
			bacterium["strain"] = "normal"


func _activate_ecology_event(event: Dictionary) -> bool:
	if String(event.get("type", "bloom")) == "bloom":
		if MAX_BACTERIA - bacteria.size() < ECOLOGY_BLOOM_SPAWN_COUNT:
			event["remaining"] = 30.0
			_show_ecology_banner("暴发延后", "培养皿细菌数量接近上限，事件将在 30 秒后重新评估。", 4.0)
			return false
		event["phase"] = "active"
		event["remaining"] = ECOLOGY_BLOOM_ACTIVE_SECONDS
		var spawned := _spawn_bloom_bacteria(event)
		_show_ecology_banner("局部细菌暴发", "%d 个高活性细菌出现；将数量压至 3 个以下可提前控制。" % spawned, 7.0)
	else:
		event["phase"] = "active"
		event["remaining"] = ECOLOGY_TOXIN_ACTIVE_SECONDS
		_show_ecology_banner("代谢毒素区形成", "抗生素分泌与解毒代谢会降低伤害，坚持 75 秒即可消散。", 7.0)
	return true


func _finish_ecology_event(event: Dictionary, contained: bool) -> void:
	var event_id := int(event.get("id", -1))
	_release_event_bacteria(event_id)
	if contained:
		lifetime_ecology_events_contained += 1
		_show_ecology_banner("生态事件已应对", "%s 已平息；长期目标进度已更新。" % _ecology_event_name(String(event.get("type", "bloom"))), 7.0)
	else:
		_show_ecology_banner("暴发期结束", "高活性阶段已经结束，但残余细菌仍留在培养皿中。", 6.0)
	ecology_events.clear()
	ecology_event_countdown = rng.randf_range(ECOLOGY_EVENT_INTERVAL_MIN, ECOLOGY_EVENT_INTERVAL_MAX)


func _update_ecology_events(sim_delta: float) -> void:
	if sim_delta <= 0.0:
		return
	if ecology_events.is_empty():
		if not _ecology_events_enabled():
			return
		ecology_event_countdown = maxf(0.0, ecology_event_countdown - sim_delta)
		if ecology_event_countdown <= 0.0:
			_begin_ecology_event()
		return
	var event: Dictionary = ecology_events[0]
	event["remaining"] = maxf(0.0, float(event.get("remaining", 0.0)) - sim_delta)
	if String(event.get("phase", "warning")) == "warning":
		if float(event["remaining"]) <= 0.0:
			_activate_ecology_event(event)
		return
	if String(event.get("type", "bloom")) == "bloom":
		var population := _count_event_bacteria(int(event.get("id", -1)))
		if int(event.get("spawned", 0)) > 0 and population <= 3:
			_finish_ecology_event(event, true)
		elif float(event["remaining"]) <= 0.0:
			_finish_ecology_event(event, false)
	elif float(event["remaining"]) <= 0.0:
		_finish_ecology_event(event, _living_core_count() > 0)


func _update_bacteria(sim_delta: float) -> void:
	if bacteria.is_empty():
		return
	var surviving: Array = []
	var children: Array = []
	var birth_slots := maxi(0, MAX_BACTERIA - bacteria.size())
	var bacteria_efficiency := _diet_efficiency("bacteria")
	var antibiotic_radius := _antibiotic_radius()
	for bacterium in bacteria:
		var pos: Vector2 = bacterium["pos"]
		var biomass := float(bacterium.get("biomass", 1.0))
		if offline_simulating and int(bacterium.get("event_id", -1)) >= 0:
			surviving.append(bacterium)
			continue
		# 捕食器和抗生素共用一次菌落距离查询，并缓存结果。
		if bacteria_efficiency > 0.0 or antibiotic_radius > 0.0:
			bacterium["contact_cooldown"] = maxf(0.0, float(bacterium.get("contact_cooldown", 0.0)) - sim_delta)
			if float(bacterium["contact_cooldown"]) <= 0.0:
				var colony_source := _nearest_colony_source(pos)
				var colony_distance := float(colony_source["distance"])
				bacterium["colony_distance"] = colony_distance
				bacterium["contact_point"] = colony_source["point"]
				bacterium["in_contact"] = bacteria_efficiency > 0.0 and colony_distance <= _bacteria_capture_radius()
				bacterium["suppressed"] = antibiotic_radius > 0.0 and colony_distance <= antibiotic_radius
				bacterium["contact_cooldown"] = BACTERIA_CONTACT_SCAN_SECONDS
		else:
			bacterium["in_contact"] = false
			bacterium["suppressed"] = false
		var bacteria_rate_multiplier := _antibiotic_bacteria_multiplier() if bool(bacterium.get("suppressed", false)) else 1.0
		var resource := _resource_by_id(int(bacterium.get("resource_id", -1)))
		if resource.is_empty() or not bool(resource.get("alive", false)) or int(resource.get("kind", -1)) != 0 or pos.distance_to(resource["pos"]) > BACTERIA_ABSORB_RADIUS:
			bacterium["seek_cooldown"] = maxf(0.0, float(bacterium.get("seek_cooldown", 0.0)) - sim_delta)
			if float(bacterium["seek_cooldown"]) <= 0.0:
				resource = _nearest_organic_resource(pos, BACTERIA_ABSORB_RADIUS)
				bacterium["resource_id"] = int(resource.get("id", -1))
				bacterium["seek_cooldown"] = BACTERIA_RESOURCE_SCAN_SECONDS
			else:
				resource = {}
		if not resource.is_empty():
			var taken := minf(float(resource["amount"]), BACTERIA_ABSORB_RATE * biomass * bacteria_rate_multiplier * sim_delta)
			resource["amount"] = maxf(0.0, float(resource["amount"]) - taken)
			bacterium["stored"] = float(bacterium.get("stored", 0.0)) + taken
			if float(resource["amount"]) <= 0.0005:
				resource["amount"] = 0.0
				resource["alive"] = false
				bacterium["resource_id"] = -1
		bacterium["cooldown"] = maxf(0.0, float(bacterium.get("cooldown", 0.0)) - sim_delta * bacteria_rate_multiplier)
		# 解锁细菌食性后，接触主菌丝或核心的细菌会被缓慢捕食。
		if bacteria_efficiency > 0.0 and bool(bacterium.get("in_contact", false)):
			var eaten := minf(biomass, BACTERIA_PREDATION_RATE * bacteria_efficiency * _bacteria_digestion_multiplier() * sim_delta)
			biomass -= eaten
			organic += eaten
			lifetime_organic_absorbed += eaten
			bacterium["biomass"] = biomass
		if biomass <= 0.0005:
			lifetime_bacteria_consumed += 1
			continue
		surviving.append(bacterium)
		if float(bacterium.get("stored", 0.0)) >= BACTERIA_DIVISION_NUTRIENT and float(bacterium["cooldown"]) <= 0.0 and children.size() < birth_slots:
			bacterium["stored"] = float(bacterium["stored"]) - BACTERIA_DIVISION_NUTRIENT
			bacterium["cooldown"] = BACTERIA_DIVISION_COOLDOWN
			var child_pos := pos + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(10.0, 24.0)
			var child := _make_bacterium(child_pos)
			child["stored"] = 0.0
			child["cooldown"] = BACTERIA_DIVISION_COOLDOWN
			child["event_id"] = int(bacterium.get("event_id", -1))
			child["strain"] = String(bacterium.get("strain", "normal"))
			children.append(child)
			lifetime_bacteria_births += 1
	if surviving.size() + children.size() > MAX_BACTERIA:
		children.resize(maxi(0, MAX_BACTERIA - surviving.size()))
	bacteria = surviving
	bacteria.append_array(children)


func _ecology_toxin_damage_rate_at(pos: Vector2) -> float:
	if offline_simulating:
		return 0.0
	var event := _current_ecology_event()
	if event.is_empty() or String(event.get("phase", "warning")) != "active" or String(event.get("type", "")) != "toxin":
		return 0.0
	if pos.distance_squared_to(event["pos"]) > float(event.get("radius", ECOLOGY_TOXIN_ZONE_RADIUS)) * float(event.get("radius", ECOLOGY_TOXIN_ZONE_RADIUS)):
		return 0.0
	var antibiotic_level := clampi(int(bacteria_components.get("antibiotic", 0)), 0, 3)
	var antibiotic_multipliers := [1.0, 0.75, 0.50, 0.25]
	return ECOLOGY_TOXIN_DAMAGE_RATE * float(antibiotic_multipliers[antibiotic_level]) * _toxin_damage_multiplier()


func _update_core_hazards(sim_delta: float) -> void:
	for core_id in range(cores.size()):
		var core: Dictionary = cores[core_id]
		if not bool(core.get("alive", true)):
			core["toxin_pressure"] = 0.0
			continue
		var core_pos: Vector2 = core["pos"]
		var toxin_units := 0.0
		for bacterium in bacteria:
			if offline_simulating and int(bacterium.get("event_id", -1)) >= 0:
				continue
			var strain := String(bacterium.get("strain", "normal"))
			var toxin_radius := BACTERIA_TOXIN_RADIUS
			if strain == "bloom":
				toxin_radius = 56.0
			if core_pos.distance_squared_to(bacterium["pos"]) > toxin_radius * toxin_radius:
				continue
			var suppression := 0.25 if bool(bacterium.get("suppressed", false)) else 1.0
			var strain_multiplier := ECOLOGY_BLOOM_TOXIN_MULTIPLIER if strain == "bloom" else 1.0
			toxin_units += float(bacterium.get("biomass", 1.0)) * suppression * strain_multiplier
		var bacteria_damage_rate := minf(CORE_MAX_TOXIN_DAMAGE_RATE, toxin_units * BACTERIA_TOXIN_DAMAGE_RATE) * _toxin_damage_multiplier()
		var damage_rate := minf(CORE_MAX_TOXIN_DAMAGE_RATE, bacteria_damage_rate + _ecology_toxin_damage_rate_at(core_pos))
		core["toxin_pressure"] = damage_rate
		if damage_rate > 0.0:
			_damage_core(core_id, damage_rate * sim_delta, "细菌毒素")
		if not _is_core_alive(core_id):
			continue
		var maximum := float(core.get("max_biomass", CORE_MAX_BIOMASS))
		var missing := maxf(0.0, maximum - float(core.get("biomass", maximum)))
		var reserve := maxf(0.0, float(core.get("repair_reserve", 0.0)))
		if missing > 0.0 and reserve > 0.0:
			var reserve_recovery := minf(missing, minf(reserve, _repair_recovery_rate() * sim_delta))
			core["biomass"] = float(core["biomass"]) + reserve_recovery
			core["repair_reserve"] = reserve - reserve_recovery
			missing -= reserve_recovery
		if missing > 0.0 and damage_rate <= 0.000001:
			core["biomass"] = minf(maximum, float(core["biomass"]) + _passive_recovery_rate() * sim_delta)
		core["repair_reserve"] = minf(float(core.get("repair_reserve", 0.0)), maxf(0.0, maximum - float(core["biomass"])))


func _damage_core(core_id: int, amount: float, source: String = "环境压力") -> void:
	if not _is_core_alive(core_id) or amount <= 0.0:
		return
	var core: Dictionary = cores[core_id]
	core["biomass"] = maxf(0.0, float(core.get("biomass", CORE_MAX_BIOMASS)) - amount)
	if float(core["biomass"]) <= 0.0005:
		_kill_core(core_id, source)


func _repair_core(core_id: int) -> void:
	if not _is_core_alive(core_id):
		toast("失活核心无法自行修复", 3.0)
		return
	var core: Dictionary = cores[core_id]
	var maximum := float(core.get("max_biomass", CORE_MAX_BIOMASS))
	var biomass := float(core.get("biomass", maximum))
	var reserve := float(core.get("repair_reserve", 0.0))
	if biomass + reserve >= maximum - 0.0005:
		toast("该核心生物量已经充足", 2.5)
		return
	if organic < CORE_REPAIR_ORGANIC_COST:
		toast("修复需要 %.3f 有机营养" % CORE_REPAIR_ORGANIC_COST, 3.0)
		return
	organic -= CORE_REPAIR_ORGANIC_COST
	var added_reserve := minf(_repair_reserve_purchase_amount(), maximum - biomass - reserve)
	core["repair_reserve"] = reserve + added_reserve
	toast("修复储备 +%.3f　将以 %.3f / 秒缓慢恢复" % [added_reserve, _repair_recovery_rate()], 4.0)


func _kill_core(core_id: int, source: String) -> void:
	if not _is_core_alive(core_id):
		return
	var core: Dictionary = cores[core_id]
	core["alive"] = false
	core["biomass"] = 0.0
	core["toxin_pressure"] = 0.0
	core["repair_reserve"] = 0.0
	(core["jobs"] as Array).clear()
	(core.get("spore_jobs", []) as Array).clear()
	for segment in segments:
		if int(segment["core_id"]) == core_id:
			segment["orphaned"] = true
			segment["viability"] = float(segment.get("viability", 1.0))
	var remaining_feeders: Array = []
	for feeder in feeders:
		if int(feeder.get("core_id", -1)) != core_id:
			remaining_feeders.append(feeder)
	feeders = remaining_feeders
	if selected_core == core_id or selected_tip_core == core_id:
		selected_core = -1
		selected_tip_valid = false
	toast("孢子核心 %d 因%s失活；其菌丝网络开始衰退" % [core_id + 1, source], 6.0)
	if _living_core_count() <= 0:
		game_over = true
		sim_speed = 0.0
		selected_expedition_ids.clear()


func _update_orphaned_segments(sim_delta: float) -> void:
	var rescued_networks := {}
	for segment in segments:
		if not bool(segment.get("orphaned", false)):
			continue
		var old_core_id := int(segment["core_id"])
		if rescued_networks.has(old_core_id):
			continue
		var rescuer := _find_rescuing_core(segment)
		if rescuer >= 0:
			_rescue_orphan_network(old_core_id, rescuer)
			rescued_networks[old_core_id] = true
		else:
			segment["viability"] = maxf(0.0, float(segment.get("viability", 1.0)) - sim_delta / ORPHAN_HYPHA_DECAY_SECONDS)
	var surviving_segments: Array = []
	for segment in segments:
		if float(segment.get("viability", 1.0)) > 0.0005:
			surviving_segments.append(segment)
	segments = surviving_segments


func _find_rescuing_core(orphan: Dictionary) -> int:
	var a: Vector2 = orphan["a"]
	var b: Vector2 = (orphan["a"] as Vector2).lerp(orphan["b"], float(orphan.get("growth", 1.0)))
	for core_id in range(cores.size()):
		if not _is_core_alive(core_id):
			continue
		if _distance_to_line_segment(cores[core_id]["pos"], a, b) <= ORPHAN_RESCUE_DISTANCE:
			return core_id
	for living_segment in segments:
		if bool(living_segment.get("orphaned", false)) or not _is_core_alive(int(living_segment["core_id"])):
			continue
		var la: Vector2 = living_segment["a"]
		var lb: Vector2 = (living_segment["a"] as Vector2).lerp(living_segment["b"], float(living_segment.get("growth", 1.0)))
		if _distance_to_line_segment(a, la, lb) <= ORPHAN_RESCUE_DISTANCE or _distance_to_line_segment(b, la, lb) <= ORPHAN_RESCUE_DISTANCE or _distance_to_line_segment(la, a, b) <= ORPHAN_RESCUE_DISTANCE or _distance_to_line_segment(lb, a, b) <= ORPHAN_RESCUE_DISTANCE:
			return int(living_segment["core_id"])
	return -1


func _rescue_orphan_network(old_core_id: int, new_core_id: int) -> void:
	var rescued := 0
	for segment in segments:
		if int(segment["core_id"]) == old_core_id and bool(segment.get("orphaned", false)):
			segment["core_id"] = new_core_id
			segment["orphaned"] = false
			segment["viability"] = 1.0
			rescued += 1
	if rescued > 0:
		toast("核心 %d 接管了 %d 段孤立菌丝" % [new_core_id + 1, rescued], 5.0)


func _is_core_alive(core_id: int) -> bool:
	return core_id >= 0 and core_id < cores.size() and bool(cores[core_id].get("alive", true))


func _living_core_count() -> int:
	var count := 0
	for core_id in range(cores.size()):
		if _is_core_alive(core_id):
			count += 1
	return count


func _nearest_organic_resource(pos: Vector2, radius: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := radius * radius
	var center := _resource_cell(pos)
	var cell_radius := maxi(1, int(ceil(radius / RESOURCE_GRID_CELL_SIZE)))
	for cy in range(center.y - cell_radius, center.y + cell_radius + 1):
		for cx in range(center.x - cell_radius, center.x + cell_radius + 1):
			var ids: Array = resource_grid.get(Vector2i(cx, cy), [])
			for resource_id in ids:
				var resource := _resource_by_id(int(resource_id))
				if resource.is_empty() or not bool(resource["alive"]) or int(resource["kind"]) != 0 or float(resource["amount"]) <= 0.0005:
					continue
				var distance := pos.distance_squared_to(resource["pos"])
				if distance <= best_distance:
					best_distance = distance
					best = resource
	return best


func _resource_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / RESOURCE_GRID_CELL_SIZE), floori(pos.y / RESOURCE_GRID_CELL_SIZE))


func _rebuild_resource_grid() -> void:
	resource_grid.clear()
	for resource in resources:
		var cell := _resource_cell(resource["pos"])
		if not resource_grid.has(cell):
			resource_grid[cell] = []
		(resource_grid[cell] as Array).append(int(resource["id"]))


func _resource_by_id(resource_id: int) -> Dictionary:
	if resource_id >= 0 and resource_id < resources.size() and int(resources[resource_id]["id"]) == resource_id:
		return resources[resource_id]
	for resource in resources:
		if int(resource["id"]) == resource_id:
			return resource
	return {}


func _nearest_colony_source(p: Vector2) -> Dictionary:
	var best := Vector2.ZERO
	var best_distance := INF
	var best_core_id := -1
	for i in range(cores.size()):
		if not _is_core_alive(i):
			continue
		var core = cores[i]
		var core_pos: Vector2 = core["pos"]
		var distance := p.distance_squared_to(core_pos)
		if distance < best_distance:
			best_distance = distance
			best = core_pos
			best_core_id = i
	for segment in segments:
		if bool(segment.get("orphaned", false)) or not _is_core_alive(int(segment["core_id"])):
			continue
		var a: Vector2 = segment["a"]
		var full_b: Vector2 = segment["b"]
		var b := a.lerp(full_b, float(segment["growth"]))
		var ab := b - a
		var t := 0.0 if ab.length_squared() < 0.001 else clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var point := a + ab * t
		var distance := p.distance_squared_to(point)
		if distance < best_distance:
			best_distance = distance
			best = point
			best_core_id = int(segment["core_id"])
	return {"point": best, "core_id": best_core_id, "distance": sqrt(best_distance)}


func _nearest_colony_point(p: Vector2) -> Vector2:
	return _nearest_colony_source(p)["point"]


func _feeder_range_for_core(core_id: int) -> float:
	if not _is_core_alive(core_id):
		return FEEDER_SENSE_RADIUS
	return FEEDER_SENSE_RADIUS + float(cores[core_id].get("feeder_range_level", 0)) * FEEDER_RANGE_PER_LEVEL


func _feeder_upgrade_cost(core_id: int) -> float:
	if core_id < 0 or core_id >= cores.size():
		return INF
	var level := int(cores[core_id].get("feeder_range_level", 0))
	if level >= MAX_FEEDER_RANGE_LEVEL:
		return INF
	return float(FEEDER_RANGE_UPGRADE_COSTS[level])


func _distance_to_colony(p: Vector2) -> float:
	var best := INF
	for core_id in range(cores.size()):
		if _is_core_alive(core_id):
			best = min(best, p.distance_to(cores[core_id]["pos"]))
	for segment in segments:
		if bool(segment.get("orphaned", false)) or not _is_core_alive(int(segment["core_id"])):
			continue
		var a: Vector2 = segment["a"]
		var b: Vector2 = a.lerp(segment["b"], float(segment["growth"]))
		best = min(best, _distance_to_line_segment(p, a, b))
	return best


func _distance_to_line_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() < 0.001:
		return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _unhandled_input(event: InputEvent) -> void:
	if splash_active:
		return
	if main_menu_active:
		if event is InputEventMouseMotion:
			last_mouse = event.position
			queue_redraw()
		elif event is InputEventMouseButton:
			last_mouse = event.position
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_handle_main_menu_click(event.position)
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE and main_menu_page == "settings":
				main_menu_page = "main"
				queue_redraw()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				if main_menu_page == "main":
					_start_game_from_menu()
		return
	if offline_report_open:
		if event is InputEventMouseMotion:
			last_mouse = event.position
			queue_redraw()
		elif event is InputEventMouseButton:
			last_mouse = event.position
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				if _offline_report_button_rect(get_viewport_rect().size).has_point(event.position):
					_close_offline_report()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
				_close_offline_report()
		return
	if event is InputEventMouseMotion:
		last_mouse = event.position
		if left_selecting:
			selection_current = event.position
			if selection_start.distance_to(selection_current) > 8.0:
				left_dragged = true
			queue_redraw()
			return
		if dragging:
			if drag_button == MOUSE_BUTTON_MIDDLE or right_press_pos.distance_to(event.position) > 6.0:
				right_dragged = true
				camera_center -= event.relative / camera_zoom
				_clamp_camera()
				queue_redraw()
			return
	if event is InputEventMouseButton:
		last_mouse = event.position
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_at(event.position, 1.12)
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_at(event.position, 1.0 / 1.12)
			return
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			drag_button = MOUSE_BUTTON_MIDDLE if event.pressed else 0
			return
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				drag_button = MOUSE_BUTTON_RIGHT
				right_press_pos = event.position
				right_dragged = false
			else:
				dragging = false
				drag_button = 0
				if not right_dragged:
					_issue_expedition_command(event.position)
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				left_selecting = true
				left_dragged = false
				selection_start = event.position
				selection_current = event.position
			else:
				left_selecting = false
				selection_current = event.position
				if left_dragged:
					_select_expedition_box(selection_start, selection_current)
				else:
					_handle_left_click(event.position)
				left_dragged = false
			return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			_save_game()
			toast("已保存", 2.0)
		elif event.keycode == KEY_E:
			upgrade_open = not upgrade_open
			if upgrade_open:
				goals_open = false
				upgrade_core_id = selected_core if selected_core >= 0 else 0
				selected_core = -1
				selected_tip_valid = false
		elif event.keycode == KEY_G:
			goals_open = not goals_open
			if goals_open:
				upgrade_open = false
				selected_core = -1
				selected_tip_valid = false
		elif event.keycode == KEY_ESCAPE:
			if upgrade_open:
				upgrade_open = false
				return
			if goals_open:
				goals_open = false
				return
			mode = "normal"
			selected_tip_valid = false
			show_status = false
			queue_redraw()


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := screen_to_world(screen_pos)
	camera_zoom = clamp(camera_zoom * factor, 0.018, 2.4)
	var after := screen_to_world(screen_pos)
	camera_center += before - after
	_clamp_camera()
	queue_redraw()


func _handle_left_click(pos: Vector2) -> void:
	if game_over:
		return
	if upgrade_open:
		_handle_upgrade_click(pos)
		return
	if goals_open:
		_handle_goals_click(pos)
		return
	if not _current_ecology_event().is_empty() and _ecology_event_hud_rect().has_point(pos):
		camera_center = _current_ecology_event()["pos"]
		_clamp_camera()
		toast("镜头已定位到生态事件区域", 2.0)
		return
	if _upgrade_hud_rect().has_point(pos):
		upgrade_open = true
		upgrade_core_id = selected_core if selected_core >= 0 else 0
		selected_core = -1
		selected_tip_valid = false
		show_status = false
		return
	if _goals_hud_rect().has_point(pos):
		goals_open = true
		upgrade_open = false
		selected_core = -1
		selected_tip_valid = false
		show_status = false
		return
	var speed_hit := _speed_button_at(pos)
	if speed_hit > 0.0:
		sim_speed = speed_hit
		toast("测试速度：%d×" % int(sim_speed), 1.5)
		return
	if _minimap_rect().has_point(pos):
		var mini := _minimap_rect()
		var uv := (pos - mini.position) / mini.size
		camera_center = Vector2(lerp(-WORLD_HALF, WORLD_HALF, uv.x), lerp(-WORLD_HALF, WORLD_HALF, uv.y))
		_clamp_camera()
		return
	var action := _menu_action_at(pos)
	if action != "":
		_apply_menu_action(action)
		return
	if mode == "place_barracks":
		var barracks_tip := _tip_at(pos)
		if barracks_tip.is_empty() or int(barracks_tip.get("core_id", -1)) != selected_core:
			toast("请点击绿色高亮的成熟菌丝末端", 2.5)
			return
		selected_tip = barracks_tip["pos"]
		selected_tip_core = int(barracks_tip["core_id"])
		selected_tip_valid = true
		_create_barracks_core()
		return
	if mode == "extend":
		_confirm_extension(screen_to_world(pos))
		return
	var expedition_hit := _expedition_unit_at_screen(pos)
	if expedition_hit >= 0:
		selected_expedition_ids = [expedition_hit]
		selected_core = -1
		selected_tip_valid = false
		mode = "normal"
		show_status = false
		return
	var core_hit := _core_at(pos)
	if core_hit >= 0:
		selected_expedition_ids.clear()
		selected_core = core_hit
		selected_tip_valid = false
		mode = "normal"
		show_status = false
		menu_anim = 0.0
		return
	var tip_hit := _tip_at(pos)
	if not tip_hit.is_empty():
		selected_expedition_ids.clear()
		selected_tip = tip_hit["pos"]
		selected_tip_core = int(tip_hit["core_id"])
		selected_tip_valid = true
		selected_core = -1
		mode = "normal"
		show_status = false
		menu_anim = 0.0
		return
	selected_core = -1
	selected_expedition_ids.clear()
	selected_tip_valid = false
	show_status = false
	mode = "normal"


func _menu_action_at(pos: Vector2) -> String:
	for button in _current_menu_buttons():
		if pos.distance_to(button["pos"]) <= float(button["radius"]):
			return button["action"]
	return ""


func _apply_menu_action(action: String) -> void:
	match action:
		"extend_core":
			mode = "extend"
			selected_tip_valid = false
			toast("移动鼠标选择方向和长度，左键确认；右键拖动视野", 4.0)
		"extend_tip":
			mode = "extend"
			toast("从这个菌丝末端继续生长", 2.5)
		"dna":
			_queue_dna(selected_core)
		"queue_spore":
			_queue_expedition_spore(selected_core)
		"cycle_spore_unit":
			_cycle_barracks_unit(selected_core)
		"upgrade_feeder_range":
			_upgrade_feeder_range(selected_core)
		"repair_core":
			_repair_core(selected_core)
		"status":
			show_status = not show_status
		"new_core":
			_create_secondary_core()
		"new_barracks":
			_create_barracks_core()
		"barracks_mode":
			mode = "place_barracks"
			selected_tip_valid = false
			show_status = false
			toast("兵营建造：点击绿色高亮的成熟菌丝末端", 4.0)
		"close":
			selected_core = -1
			selected_tip_valid = false
			show_status = false


func _upgrade_feeder_range(core_id: int) -> void:
	if not _is_core_alive(core_id):
		return
	var level := int(cores[core_id].get("feeder_range_level", 0))
	if level >= MAX_FEEDER_RANGE_LEVEL:
		toast("细菌丝延展范围已达到当前上限", 3.0)
		return
	var cost := _feeder_upgrade_cost(core_id)
	if organic < cost:
		toast("有机营养不足：本次强化需要 %.3f" % cost, 3.0)
		return
	organic -= cost
	level += 1
	cores[core_id]["feeder_range_level"] = level
	toast("节点 Lv.%d　范围 %.0f μm　DNA 速度 +%d%%" % [level, _feeder_range_for_core(core_id) / 2.0, int(_dna_speed_bonus(core_id) * 100.0)], 4.0)


func _queue_dna(core_id: int) -> void:
	if not _is_core_alive(core_id):
		return
	if organic < DNA_ORGANIC_COST or mineral < DNA_MINERAL_COST:
		toast("资源不足：需要 30 有机营养与 1 矿物离子", 3.0)
		return
	organic -= DNA_ORGANIC_COST
	mineral -= DNA_MINERAL_COST
	var jobs: Array = cores[core_id]["jobs"]
	var duration := _dna_job_duration(core_id)
	jobs.append({"remaining": duration, "total": duration})
	toast("DNA 生产已排队（核心队列 %d）" % jobs.size(), 3.0)


func _dna_job_duration(core_id: int) -> float:
	if core_id < 0 or core_id >= cores.size():
		return DNA_JOB_SECONDS
	var level := int(cores[core_id].get("feeder_range_level", 0))
	return DNA_JOB_SECONDS / (1.0 + level * DNA_SPEED_BONUS_PER_NODE_LEVEL)


func _dna_speed_bonus(core_id: int) -> float:
	if core_id < 0 or core_id >= cores.size():
		return 0.0
	return int(cores[core_id].get("feeder_range_level", 0)) * DNA_SPEED_BONUS_PER_NODE_LEVEL


func _diet_unlock_cost() -> int:
	return int(DIET_UNLOCK_BASE_COST * pow(10.0, diet_order.size()))


func _diet_level_cost(diet_id: String) -> int:
	var level := int(diet_levels.get(diet_id, 0))
	if level <= 0 or level >= 5:
		return 0
	return int(DIET_LEVEL_COSTS[level - 1])


func _diet_efficiency(diet_id: String) -> float:
	var level := clampi(int(diet_levels.get(diet_id, 0)), 0, 5)
	return float(DIET_EFFICIENCIES[level])


func _purchase_diet(diet_id: String) -> void:
	if not DIET_IDS.has(diet_id):
		return
	var level := int(diet_levels.get(diet_id, 0))
	if level == 0:
		var unlock_cost := _diet_unlock_cost()
		if dna < unlock_cost:
			toast("DNA 不足：建立新食性需要 %d" % unlock_cost, 3.0)
			return
		dna -= unlock_cost
		diet_levels[diet_id] = 1
		diet_order.append(diet_id)
		toast("已确立%s　初始吸收效率 20%%" % DIET_NAMES[diet_id], 4.0)
		return
	if level >= 5:
		toast("%s吸收效率已达到 100%%" % DIET_NAMES[diet_id], 3.0)
		return
	var level_cost := _diet_level_cost(diet_id)
	if dna < level_cost:
		toast("DNA 不足：效率升级需要 %d" % level_cost, 3.0)
		return
	dna -= level_cost
	diet_levels[diet_id] = level + 1
	toast("%s效率提升至 %d%%" % [DIET_NAMES[diet_id], int(_diet_efficiency(diet_id) * 100.0)], 4.0)


func _purchase_barracks_unit(unit_id: String) -> void:
	if unit_id == "forager" or bool(barracks_unit_unlocks.get(unit_id, false)):
		return
	var cost := int(BARRACK_UNIT_UNLOCK_COSTS.get(unit_id, 0))
	if cost <= 0:
		return
	if dna < cost:
		toast("DNA 不足：解锁%s需要 %d" % [BARRACK_UNIT_NAMES.get(unit_id, unit_id), cost], 3.0)
		return
	dna -= cost
	barracks_unit_unlocks[unit_id] = true
	toast("已解锁%s；现在可在兵营切换生产" % BARRACK_UNIT_NAMES.get(unit_id, unit_id), 4.0)


func _scout_upgrade_cost(upgrade_id: String) -> int:
	var level := int(scout_upgrade_levels.get(upgrade_id, 0))
	if level < 0 or level >= MAX_SCOUT_UPGRADE_LEVEL:
		return 0
	return int(SCOUT_UPGRADE_COSTS[level])


func _purchase_scout_upgrade(upgrade_id: String) -> void:
	if not SCOUT_UPGRADE_IDS.has(upgrade_id) or not bool(barracks_unit_unlocks.get("scout", false)):
		return
	var level := int(scout_upgrade_levels.get(upgrade_id, 0))
	if level >= MAX_SCOUT_UPGRADE_LEVEL:
		toast("%s已达到最高等级" % SCOUT_UPGRADE_NAMES[upgrade_id], 3.0)
		return
	var cost := _scout_upgrade_cost(upgrade_id)
	if dna < cost:
		toast("DNA 不足：强化%s需要 %d" % [SCOUT_UPGRADE_NAMES[upgrade_id], cost], 3.0)
		return
	dna -= cost
	scout_upgrade_levels[upgrade_id] = level + 1
	if upgrade_id == "vision":
		for unit in expedition_units:
			if String(unit.get("unit_type", "forager")) == "scout":
				unit["reveal_cell"] = -1
		_update_exploration()
	toast("%s提升至 Lv.%d" % [SCOUT_UPGRADE_NAMES[upgrade_id], level + 1], 3.0)


func _purchase_diet_unit(diet_id: String, unit_id: String) -> void:
	if int(diet_levels.get(diet_id, 0)) <= 0:
		toast("需要先确立%s" % DIET_NAMES.get(diet_id, "对应食性"), 3.0)
		return
	if bool(diet_unit_unlocks.get(unit_id, false)):
		return
	var definition: Dictionary = {}
	for item in DIET_SPECIAL_UNITS.get(diet_id, []):
		if String(item.get("id", "")) == unit_id:
			definition = item
			break
	if definition.is_empty():
		return
	if not bool(definition.get("available", false)):
		toast(String(definition.get("requirement", "该生态尚未开放")), 3.0)
		return
	var cost := int(definition.get("cost", 0))
	if dna < cost:
		toast("DNA 不足：解锁%s需要 %d" % [definition.get("name", unit_id), cost], 3.0)
		return
	dna -= cost
	diet_unit_unlocks[unit_id] = true
	toast("已解锁%s；兵营生产列表已更新" % definition.get("name", unit_id), 4.0)


func _bacteria_component_cost(component_id: String) -> int:
	var level := int(bacteria_components.get(component_id, 0))
	if not BACTERIA_COMPONENT_COSTS.has(component_id) or level >= 3:
		return 0
	return int((BACTERIA_COMPONENT_COSTS[component_id] as Array)[level])


func _purchase_bacteria_component(component_id: String) -> void:
	if int(diet_levels.get("bacteria", 0)) <= 0:
		toast("需要先确立细菌食性", 3.0)
		return
	if not BACTERIA_COMPONENT_IDS.has(component_id):
		return
	var level := int(bacteria_components.get(component_id, 0))
	if level >= 3:
		toast("%s已达到当前上限" % BACTERIA_COMPONENT_NAMES[component_id], 3.0)
		return
	var cost := _bacteria_component_cost(component_id)
	if dna < cost:
		toast("DNA 不足：本次进化需要 %d" % cost, 3.0)
		return
	dna -= cost
	bacteria_components[component_id] = level + 1
	toast("%s　Lv.%d / 3" % [BACTERIA_COMPONENT_NAMES[component_id], level + 1], 4.0)


func _bacteria_capture_radius() -> float:
	return BACTERIA_PREDATION_RADIUS + int(bacteria_components.get("trap", 0)) * 16.0


func _bacteria_digestion_multiplier() -> float:
	return 1.0 + int(bacteria_components.get("enzymes", 0)) * 0.35


func _antibiotic_radius() -> float:
	var level := int(bacteria_components.get("antibiotic", 0))
	return 0.0 if level <= 0 else 50.0 + level * 30.0


func _antibiotic_bacteria_multiplier() -> float:
	return [1.0, 0.75, 0.50, 0.25][clampi(int(bacteria_components.get("antibiotic", 0)), 0, 3)]


func _structure_cost(structure_id: String) -> int:
	var level := int(structure_levels.get(structure_id, 0))
	if not STRUCTURE_IDS.has(structure_id) or level >= 4:
		return 0
	return int(STRUCTURE_LEVEL_COSTS[level])


func _purchase_structure(structure_id: String) -> void:
	if not STRUCTURE_IDS.has(structure_id):
		return
	var level := int(structure_levels.get(structure_id, 0))
	if level >= 4:
		toast("%s已达到当前上限" % STRUCTURE_NAMES[structure_id], 3.0)
		return
	var cost := _structure_cost(structure_id)
	if dna < cost:
		toast("DNA 不足：本次结构进化需要 %d" % cost, 3.0)
		return
	dna -= cost
	structure_levels[structure_id] = level + 1
	toast("%s　Lv.%d / 4" % [STRUCTURE_NAMES[structure_id], level + 1], 4.0)


func _hypha_capacity_for_core(_core_id: int) -> float:
	return BASE_TOTAL_HYPHA_CAPACITY * (1.0 + int(structure_levels.get("branching", 0)) * 0.25)


func _max_segment_length() -> float:
	return MAX_SEGMENT_LENGTH * (1.0 + int(structure_levels.get("elongation", 0)) * 0.15)


func _active_feeder_capacity() -> int:
	return MAX_ACTIVE_FEEDERS + int(structure_levels.get("feeders", 0)) * 12


func _hypha_growth_seconds() -> float:
	return 24.0 / (1.0 + int(structure_levels.get("growth", 0)) * 0.20)


func _survival_cost(survival_id: String) -> int:
	var level := int(survival_levels.get(survival_id, 0))
	if not SURVIVAL_IDS.has(survival_id) or level >= 4:
		return 0
	return int(SURVIVAL_LEVEL_COSTS[level])


func _purchase_survival(survival_id: String) -> void:
	if not SURVIVAL_IDS.has(survival_id):
		return
	var level := int(survival_levels.get(survival_id, 0))
	if level >= 4:
		toast("%s已达到当前上限" % SURVIVAL_NAMES[survival_id], 3.0)
		return
	var cost := _survival_cost(survival_id)
	if dna < cost:
		toast("DNA 不足：本次生存进化需要 %d" % cost, 3.0)
		return
	dna -= cost
	survival_levels[survival_id] = level + 1
	if survival_id == "wall":
		for core_id in range(cores.size()):
			var core: Dictionary = cores[core_id]
			core["max_biomass"] = float(core.get("max_biomass", CORE_MAX_BIOMASS)) + 25.0
			if _is_core_alive(core_id):
				core["biomass"] = minf(float(core["max_biomass"]), float(core.get("biomass", 0.0)) + 25.0)
	toast("%s　Lv.%d / 4" % [SURVIVAL_NAMES[survival_id], level + 1], 4.0)


func _core_max_biomass_value() -> float:
	return CORE_MAX_BIOMASS + int(survival_levels.get("wall", 0)) * 25.0


func _toxin_damage_multiplier() -> float:
	return maxf(0.40, 1.0 - int(survival_levels.get("detox", 0)) * 0.15)


func _passive_recovery_rate() -> float:
	return CORE_PASSIVE_RECOVERY_RATE * (1.0 + int(survival_levels.get("repair", 0)) * 0.25)


func _repair_recovery_rate() -> float:
	return CORE_REPAIR_RECOVERY_RATE * (1.0 + int(survival_levels.get("repair", 0)) * 0.20)


func _repair_reserve_purchase_amount() -> float:
	return CORE_REPAIR_AMOUNT + int(survival_levels.get("storage", 0)) * 5.0


func _create_secondary_core() -> void:
	if not selected_tip_valid:
		return
	if organic < CORE_ORGANIC_COST or mineral < CORE_MINERAL_COST:
		toast("形成核心需要 70 有机营养与 6 矿物离子", 3.0)
		return
	for core in cores:
		if selected_tip.distance_to(core["pos"]) < 70.0:
			toast("这里离现有孢子核心太近", 2.5)
			return
	organic -= CORE_ORGANIC_COST
	mineral -= CORE_MINERAL_COST
	cores.append(_make_core(selected_tip))
	selected_core = cores.size() - 1
	selected_tip_valid = false
	mode = "normal"
	toast("次级孢子核心形成：现在可以独立排队生产 DNA", 4.0)


func _create_barracks_core() -> void:
	if not selected_tip_valid:
		return
	if organic < BARRACKS_ORGANIC_COST or mineral < BARRACKS_MINERAL_COST or dna < BARRACKS_DNA_COST:
		toast("兵营核心需要 %.3f 有机、%.3f 矿物与 %d DNA" % [BARRACKS_ORGANIC_COST, BARRACKS_MINERAL_COST, BARRACKS_DNA_COST], 4.0)
		return
	for core in cores:
		if selected_tip.distance_to(core["pos"]) < 70.0:
			toast("这里离现有核心太近", 2.5)
			return
	organic -= BARRACKS_ORGANIC_COST
	mineral -= BARRACKS_MINERAL_COST
	dna -= BARRACKS_DNA_COST
	cores.append(_make_core(selected_tip, "barracks"))
	selected_core = cores.size() - 1
	selected_tip_valid = false
	mode = "normal"
	toast("兵营核心形成：可生产已解锁的体外部队", 4.0)


func _confirm_extension(target: Vector2) -> void:
	var core_id := selected_tip_core if selected_tip_valid else selected_core
	if not _is_core_alive(core_id):
		mode = "normal"
		return
	var source := selected_tip if selected_tip_valid else _best_source(core_id, target)
	var vector := target - source
	var length := vector.length()
	if length < MIN_SEGMENT_LENGTH:
		toast("菌丝太短；请把目标移远一些", 2.0)
		return
	if length > _max_segment_length():
		target = source + vector.normalized() * _max_segment_length()
		length = _max_segment_length()
	var remaining := _hypha_capacity_for_core(core_id) - _core_hypha_length(core_id)
	if length > remaining:
		if remaining < MIN_SEGMENT_LENGTH:
			toast("当前核心的菌丝容量已达上限；后续可通过进化提升", 3.0)
			return
		target = source + vector.normalized() * remaining
		length = remaining
	var cost := int(ceil(length / ORGANIC_PER_LENGTH))
	if organic < cost:
		toast("有机营养不足：本段需要 %d" % cost, 2.5)
		return
	organic -= cost
	segments.append({
		"a": source,
		"b": target,
		"growth": 0.0,
		"core_id": core_id,
		"curve": rng.randf_range(-0.13, 0.13),
		"orphaned": false,
		"viability": 1.0
	})
	selected_tip_valid = false
	selected_core = core_id
	mode = "normal"
	toast("菌丝开始生长　消耗有机营养 %d" % cost, 2.5)


func _best_source(core_id: int, target: Vector2) -> Vector2:
	var best: Vector2 = cores[core_id]["pos"]
	var best_distance := best.distance_squared_to(target)
	for segment in segments:
		if int(segment["core_id"]) != core_id or bool(segment.get("orphaned", false)) or float(segment["growth"]) < 1.0:
			continue
		var p: Vector2 = segment["b"]
		var d := p.distance_squared_to(target)
		if d < best_distance:
			best_distance = d
			best = p
	return best


func _core_hypha_length(core_id: int) -> float:
	var total := 0.0
	for segment in segments:
		if int(segment["core_id"]) == core_id:
			total += (segment["b"] as Vector2).distance_to(segment["a"])
	return total


func _core_at(screen_pos: Vector2) -> int:
	for i in range(cores.size() - 1, -1, -1):
		if not _is_core_alive(i):
			continue
		var p := world_to_screen(cores[i]["pos"])
		if screen_pos.distance_to(p) <= 25.0 * camera_zoom + 7.0:
			return i
	return -1


func _tip_at(screen_pos: Vector2) -> Dictionary:
	for i in range(segments.size() - 1, -1, -1):
		var segment = segments[i]
		if bool(segment.get("orphaned", false)) or not _is_core_alive(int(segment["core_id"])) or float(segment["growth"]) < 1.0:
			continue
		var p: Vector2 = segment["b"]
		if screen_pos.distance_to(world_to_screen(p)) <= 12.0:
			return {"pos": p, "core_id": int(segment["core_id"])}
	return {}


func _clamp_camera() -> void:
	camera_center.x = clamp(camera_center.x, -WORLD_HALF + 400.0, WORLD_HALF - 400.0)
	camera_center.y = clamp(camera_center.y, -WORLD_HALF + 300.0, WORLD_HALF - 300.0)


func world_to_screen(world_pos: Vector2) -> Vector2:
	return (world_pos - camera_center) * camera_zoom + get_viewport_rect().size * 0.5


func screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - get_viewport_rect().size * 0.5) / camera_zoom + camera_center


func _draw() -> void:
	var viewport := get_viewport_rect().size
	if splash_active:
		_draw_splash(viewport)
		return
	if main_menu_active:
		_draw_main_menu(viewport)
		return
	draw_rect(Rect2(Vector2.ZERO, viewport), COLOR_BG)
	_draw_dish_overview(viewport)
	_draw_substrate(viewport)
	_draw_resources(viewport)
	_draw_ecology_zones(viewport)
	_draw_bacteria(viewport)
	_draw_colony(viewport)
	_draw_expedition_units(viewport)
	_draw_world_fog(viewport)
	_draw_barracks_placement_preview()
	_draw_extension_preview()
	_draw_expedition_selection()
	_draw_hud(viewport)
	_draw_selection_menu()
	if not upgrade_open and not goals_open:
		if not _draw_core_tooltip():
			_draw_bacteria_tooltip()
	if show_status and selected_core >= 0:
		_draw_status_panel(viewport)
	if upgrade_open:
		_draw_upgrade_panel(viewport)
	if goals_open:
		_draw_goals_panel(viewport)
	if game_over:
		_draw_game_over(viewport)
	if discovery_banner_time > 0.0 and discovery_banner_title != "":
		_draw_discovery_banner(viewport)
	if ecology_banner_time > 0.0 and ecology_banner_title != "":
		_draw_ecology_banner(viewport)
	if toast_time > 0.0 and toast_text != "":
		_draw_toast(viewport)
	if offline_report_open:
		_draw_offline_report(viewport)


func _draw_splash(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color.BLACK)
	var opacity := 1.0
	if splash_time < SPLASH_FADE_IN_SECONDS:
		opacity = smoothstep(0.0, 1.0, splash_time / SPLASH_FADE_IN_SECONDS)
	elif splash_time > SPLASH_FADE_IN_SECONDS + SPLASH_HOLD_SECONDS:
		var fade_time := splash_time - SPLASH_FADE_IN_SECONDS - SPLASH_HOLD_SECONDS
		opacity = 1.0 - smoothstep(0.0, 1.0, fade_time / SPLASH_FADE_OUT_SECONDS)
	var logo_size := minf(560.0, minf(viewport.y * 0.78, viewport.x * 0.52))
	var logo_rect := Rect2(_pixel_snap(viewport * 0.5 - Vector2.ONE * logo_size * 0.5 - Vector2(0, 20)), Vector2.ONE * logo_size)
	if splash_logo != null:
		draw_texture_rect(splash_logo, logo_rect, false, Color(1.0, 1.0, 1.0, opacity))
	var title := "Game: Super boring fungi"
	var title_width := fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var title_pos := Vector2(viewport.x * 0.5 - title_width * 0.5, viewport.y * 0.5 + logo_size * 0.37)
	draw_string(fallback_font, _pixel_snap(title_pos), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.72, 0.95, 0.86, opacity * 0.92))


func _main_menu_button_rect(viewport: Vector2, index: int) -> Rect2:
	var size := Vector2(320.0, 46.0)
	var first_y := viewport.y * 0.52
	return Rect2(_pixel_snap(Vector2(viewport.x * 0.5 - size.x * 0.5, first_y + index * 62.0)), size)


func _draw_main_menu(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color("020810"))
	# 静止的粗像素孢子与菌丝纹理，让菜单延续培养皿的视觉语言。
	for i in range(38):
		var x := fmod(float(i * 173 + 47), viewport.x)
		var y := fmod(float(i * 97 + 31), viewport.y)
		var size := 2.0 if i % 4 else 4.0
		draw_rect(Rect2(_pixel_snap(Vector2(x, y)), Vector2.ONE * size), Color(0.24, 0.70, 0.57, 0.10 if i % 3 else 0.18))
	var glow_center := Vector2(viewport.x * 0.5, viewport.y * 0.22)
	draw_circle(glow_center, minf(230.0, viewport.y * 0.32), Color(0.05, 0.25, 0.21, 0.20))
	var logo_size := minf(270.0, viewport.y * 0.38)
	var logo_rect := Rect2(_pixel_snap(Vector2(viewport.x * 0.5 - logo_size * 0.5, 8.0)), Vector2.ONE * logo_size)
	if splash_logo != null:
		draw_texture_rect(splash_logo, logo_rect, false)
	var title := "Game: Super boring fungi"
	var title_size := fallback_font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(fallback_font, _pixel_snap(Vector2(viewport.x * 0.5 - title_size.x * 0.5, viewport.y * 0.405)), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, COLOR_HYPHA)
	var subtitle := "第一章 · 实验室培养"
	var subtitle_size := fallback_font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE)
	draw_string(fallback_font, _pixel_snap(Vector2(viewport.x * 0.5 - subtitle_size.x * 0.5, viewport.y * 0.445)), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)

	var labels: Array[String]
	if main_menu_page == "settings":
		labels = [
			"显示模式　%s" % ("全屏" if settings_fullscreen else "窗口"),
			"像素鼠标　%s" % ("开启" if settings_pixel_cursor else "关闭"),
			"返回"
		]
	else:
		labels = ["读取存档" if main_menu_has_save else "开始培养", "设置", "退出"]
	for i in range(labels.size()):
		var rect := _main_menu_button_rect(viewport, i)
		var hovered := rect.has_point(last_mouse)
		var background := Color(0.08, 0.27, 0.23, 0.98) if hovered else Color(0.025, 0.10, 0.14, 0.96)
		var border := Color(0.39, 0.96, 0.65, 0.96) if hovered else Color(0.26, 0.62, 0.54, 0.72)
		draw_style_box(_rounded_style(background, border, 10, 2), rect)
		var label_size := fallback_font.get_string_size(labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		draw_string(fallback_font, _pixel_snap(Vector2(rect.get_center().x - label_size.x * 0.5, rect.position.y + 29.0)), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("dff7e8"))
	var hint := "检测到培养记录 · 读取后结算离线进度" if main_menu_has_save else "尚无培养记录 · 将从一个孢子核心开始"
	if main_menu_page == "settings":
		hint = "设置会自动保存 · Esc 返回"
	var hint_size := fallback_font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE)
	draw_string(fallback_font, _pixel_snap(Vector2(viewport.x * 0.5 - hint_size.x * 0.5, viewport.y * 0.52 + 205.0)), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _handle_main_menu_click(pos: Vector2) -> void:
	var viewport := get_viewport_rect().size
	for i in range(3):
		if not _main_menu_button_rect(viewport, i).has_point(pos):
			continue
		if main_menu_page == "settings":
			if i == 0:
				settings_fullscreen = not settings_fullscreen
				_apply_settings()
				_save_settings()
			elif i == 1:
				settings_pixel_cursor = not settings_pixel_cursor
				_apply_settings()
				_save_settings()
			else:
				main_menu_page = "main"
		else:
			if i == 0:
				_start_game_from_menu()
			elif i == 1:
				main_menu_page = "settings"
			else:
				get_tree().quit()
		queue_redraw()
		return


func _start_game_from_menu() -> void:
	if game_started:
		main_menu_active = false
		return
	rng.seed = 0xF00D47
	_generate_world()
	var loaded := false
	if main_menu_has_save:
		loaded = _load_game()
	if not loaded:
		_start_new_culture()
	game_started = true
	main_menu_active = false
	main_menu_page = "main"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	queue_redraw()


func _start_new_culture() -> void:
	# 这是新局的唯一初始化入口，测试和未来的“重新开始”也复用它。
	rng.seed = 0xF00D47
	_generate_world()
	cores.clear()
	segments.clear()
	feeders.clear()
	expedition_units.clear()
	explored_cells.clear()
	discovered_hotspots.clear()
	last_discovery_scan_cell_count = -1
	selected_expedition_ids.clear()
	next_expedition_id = 1
	organic = 220.0
	mineral = 24.0
	dna = 0
	camera_center = Vector2.ZERO
	camera_zoom = 0.65
	sim_speed = 1.0
	sim_time = 0.0
	absorb_clock = 0.0
	bacteria_update_clock = 0.0
	expedition_update_clock = 0.0
	save_clock = 0.0
	game_over = false
	selected_core = -1
	selected_tip_valid = false
	mode = "normal"
	upgrade_open = false
	goals_open = false
	diet_detail_id = ""
	diet_order.clear()
	for diet_id in DIET_IDS:
		diet_levels[diet_id] = 0
	for component_id in BACTERIA_COMPONENT_IDS:
		bacteria_components[component_id] = 0
	for structure_id in STRUCTURE_IDS:
		structure_levels[structure_id] = 0
	for survival_id in SURVIVAL_IDS:
		survival_levels[survival_id] = 0
	barracks_unit_unlocks = {"forager": true, "carrier": false, "chelator": false, "scout": false}
	diet_unit_unlocks = {"lytic": false}
	lifetime_organic_absorbed = 0.0
	lifetime_mineral_absorbed = 0.0
	lifetime_dna_produced = 0
	lifetime_bacteria_births = 0
	lifetime_bacteria_consumed = 0
	lifetime_expedition_organic_returned = 0.0
	lifetime_expedition_mineral_returned = 0.0
	lifetime_expedition_bacteria_killed = 0
	goals_claimed = {}
	for scout_upgrade_id in SCOUT_UPGRADE_IDS:
		scout_upgrade_levels[scout_upgrade_id] = 0
	ecology_events.clear()
	next_ecology_event_id = 1
	ecology_event_countdown = rng.randf_range(ECOLOGY_FIRST_EVENT_MIN, ECOLOGY_FIRST_EVENT_MAX)
	lifetime_ecology_events_seen = 0
	lifetime_ecology_events_contained = 0
	ecology_banner_title = ""
	ecology_banner_detail = ""
	ecology_banner_time = 0.0
	discovery_banner_title = ""
	discovery_banner_detail = ""
	discovery_banner_time = 0.0
	offline_report_open = false
	offline_report.clear()
	cores.append(_make_core(Vector2.ZERO))
	_update_exploration()
	toast("点击孢子核心，开始延伸第一条菌丝", 6.0)


func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		settings_fullscreen = bool(parsed.get("fullscreen", false))
		settings_pixel_cursor = bool(parsed.get("pixel_cursor", true))


func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"fullscreen": settings_fullscreen, "pixel_cursor": settings_pixel_cursor}))


func _apply_settings() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if settings_pixel_cursor and cursor_texture != null:
		Input.set_custom_mouse_cursor(cursor_texture, Input.CURSOR_ARROW, Vector2(4.0, 3.0))
	else:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)


func _draw_dish_overview(viewport: Vector2) -> void:
	if camera_zoom > 0.075:
		return
	var fade := clampf((0.075 - camera_zoom) / 0.035, 0.0, 1.0)
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.002, 0.007, 0.014, 0.68 + fade * 0.28))
	var center := _pixel_snap(world_to_screen(Vector2.ZERO))
	var radius := WORLD_HALF * camera_zoom
	draw_circle(center, radius, Color(0.018, 0.068, 0.11, 0.74 + fade * 0.22))
	draw_arc(center, radius, 0.0, TAU, 256, Color(0.42, 0.78, 0.73, 0.22 + fade * 0.46), maxf(1.0, 2.0 * fade), false)


func _draw_substrate(viewport: Vector2) -> void:
	if camera_zoom < 0.055:
		return
	for mark in substrate_marks:
		var p: Vector2 = _pixel_snap(world_to_screen(mark["pos"]))
		if p.x < -4 or p.y < -4 or p.x > viewport.x + 4 or p.y > viewport.y + 4:
			continue
		var size := float(mark["size"])
		draw_rect(Rect2(p, Vector2(size, size)), Color(0.22, 0.48, 0.50, float(mark["alpha"])))
	for p_world in water_motes:
		var p := _pixel_snap(world_to_screen(p_world))
		if p.x < -5 or p.y < -5 or p.x > viewport.x + 5 or p.y > viewport.y + 5:
			continue
		draw_rect(Rect2(p, Vector2(2, 2)), Color(0.35, 0.72, 0.88, 0.25))


func _draw_resources(viewport: Vector2) -> void:
	for resource in resources:
		if not bool(resource["alive"]):
			continue
		if not _is_world_explored(resource["pos"]):
			continue
		var p: Vector2 = _pixel_snap(world_to_screen(resource["pos"]))
		if p.x < -10 or p.y < -10 or p.x > viewport.x + 10 or p.y > viewport.y + 10:
			continue
		var base_color: Color = COLOR_ORGANIC if int(resource["kind"]) == 0 else COLOR_MINERAL
		var fraction := clampf(float(resource["amount"]) / maxf(0.001, float(resource["initial_amount"])), 0.0, 1.0)
		var color := base_color.darkened((1.0 - fraction) * 0.68)
		color.a = 0.04 + fraction * 0.96
		var blink := int(sim_time * 2.0 + float(resource["phase"]) * 3.0) % 5 == 0
		if int(resource["kind"]) == 0:
			var glow_alpha := (0.16 if blink else 0.08) * fraction
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(color.r, color.g, color.b, glow_alpha))
			var pixel_size := 2.0 if fraction > 0.34 else 1.0
			draw_rect(Rect2(p - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), color)
		else:
			var arm := 2.0 if fraction > 0.45 else 1.0
			draw_rect(Rect2(p - Vector2(1, arm), Vector2(2, arm * 2.0 + 1.0)), Color(color.r, color.g, color.b, 0.04 + fraction * 0.72))
			draw_rect(Rect2(p - Vector2(arm, 1), Vector2(arm * 2.0 + 1.0, 2)), color)


func _draw_ecology_zones(viewport: Vector2) -> void:
	var event := _current_ecology_event()
	if event.is_empty() or not _is_world_explored(event["pos"]):
		return
	var center := _pixel_snap(world_to_screen(event["pos"]))
	var radius_pixels := float(event.get("radius", ECOLOGY_BLOOM_RADIUS)) * camera_zoom
	if center.x + radius_pixels < -20.0 or center.y + radius_pixels < -20.0 or center.x - radius_pixels > viewport.x + 20.0 or center.y - radius_pixels > viewport.y + 20.0:
		return
	var warning := String(event.get("phase", "warning")) == "warning"
	var event_type := String(event.get("type", "bloom"))
	var color := Color("f4ca83") if warning else (Color("ff789f") if event_type == "bloom" else Color("b884ec"))
	var pulse := 0.58 + sin(sim_time * 4.0) * 0.18
	if radius_pixels < 4.0:
		draw_rect(Rect2(center - Vector2.ONE, Vector2(3, 3)), Color(color, pulse))
		return
	for i in range(40):
		var angle := TAU * float(i) / 40.0
		var point := _pixel_snap(center + Vector2.from_angle(angle) * radius_pixels)
		var pixel_size := 3.0 if i % 4 == 0 else 2.0
		draw_rect(Rect2(point - Vector2.ONE * pixel_size * 0.5, Vector2.ONE * pixel_size), Color(color, pulse if warning else 0.70))
	if not warning:
		for i in range(28):
			var angle := TAU * float((i * 13) % 28) / 28.0
			var distance := radius_pixels * (0.18 + float((i * 7) % 10) / 12.0)
			var point := _pixel_snap(center + Vector2.from_angle(angle) * distance)
			draw_rect(Rect2(point, Vector2(2, 2)), Color(color, 0.16 if event_type == "bloom" else 0.22))
	var label := "预警" if warning else _ecology_event_name(event_type)
	_draw_label_box(center + Vector2(12, -radius_pixels - 8), label, color)


func _draw_bacteria(viewport: Vector2) -> void:
	for bacterium in bacteria:
		if not _is_world_explored(bacterium["pos"]):
			continue
		var p := _pixel_snap(world_to_screen(bacterium["pos"]))
		if p.x < -10.0 or p.y < -10.0 or p.x > viewport.x + 10.0 or p.y > viewport.y + 10.0:
			continue
		var biomass := clampf(float(bacterium.get("biomass", 1.0)), 0.0, 1.0)
		var strain := String(bacterium.get("strain", "normal"))
		var base_color := Color("ff9d66") if strain == "bloom" else COLOR_BACTERIA
		var color := base_color.darkened((1.0 - biomass) * 0.62)
		color.a = 0.22 + biomass * 0.78
		if int(bacteria_components.get("trap", 0)) > 0 and bool(bacterium.get("in_contact", false)) and float(bacterium.get("colony_distance", 0.0)) > BACTERIA_PREDATION_RADIUS:
			var trap_start := _pixel_snap(world_to_screen(bacterium.get("contact_point", bacterium["pos"])))
			draw_line(trap_start, p, Color(0.64, 0.94, 0.72, 0.62), 1.0, false)
		if camera_zoom < 0.09:
			draw_rect(Rect2(p, Vector2.ONE), color)
			continue
		# 6×4 的圆角杆状像素，不使用平滑圆形贴图。
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), color)
		draw_rect(Rect2(p - Vector2(3, 1), Vector2(6, 2)), color)
		var stored_fraction := clampf(float(bacterium.get("stored", 0.0)) / BACTERIA_DIVISION_NUTRIENT, 0.0, 1.0)
		if stored_fraction >= 0.72:
			draw_rect(Rect2(p - Vector2(0, 2), Vector2(1, 4)), Color(0.36, 0.08, 0.18, 0.74))
		if bool(bacterium.get("suppressed", false)):
			draw_rect(Rect2(p + Vector2(-5, -4), Vector2(2, 2)), Color(0.55, 0.80, 1.0, 0.72))
			draw_rect(Rect2(p + Vector2(4, 3), Vector2(1, 1)), Color(0.55, 0.80, 1.0, 0.52))
		if int(sim_time * 2.0 + float(bacterium.get("phase", 0.0))) % 4 == 0:
			draw_rect(Rect2(p + Vector2(3, -2), Vector2(1, 1)), Color(base_color, 0.42))


func _draw_expedition_units(viewport: Vector2) -> void:
	var command_color := Color(0.38, 1.0, 0.56, 0.90)
	for unit in expedition_units:
		var unit_id := int(unit.get("id", -1))
		var unit_type := String(unit.get("unit_type", "forager"))
		var selected := selected_expedition_ids.has(unit_id)
		var p := _pixel_snap(world_to_screen(unit["pos"]))
		if selected and sim_time <= float(unit.get("command_until", 0.0)):
			var target_screen := _pixel_snap(world_to_screen(unit.get("target_pos", unit["pos"])))
			draw_line(p, target_screen, command_color, 1.0, false)
			draw_line(target_screen + Vector2(-5, 0), target_screen + Vector2(5, 0), command_color, 1.0, false)
			draw_line(target_screen + Vector2(0, -5), target_screen + Vector2(0, 5), command_color, 1.0, false)
		if p.x < -14.0 or p.y < -14.0 or p.x > viewport.x + 14.0 or p.y > viewport.y + 14.0:
			continue
		if camera_zoom < 0.09:
			var overview_color := COLOR_MINERAL if unit_type == "chelator" else (COLOR_BACTERIA if unit_type == "lytic" else (Color("5edcf5") if unit_type == "scout" else Color("76f5ca")))
			draw_rect(Rect2(p, Vector2.ONE), overview_color)
			continue
		var phase := float(unit.get("phase", 0.0)) + sim_time * 4.0
		var tail_offset := Vector2(-4.0, sin(phase) * 2.0)
		var body_color := Color("76f5ca")
		if unit_type == "carrier": body_color = COLOR_ORGANIC
		elif unit_type == "chelator": body_color = COLOR_MINERAL
		elif unit_type == "scout": body_color = Color("5edcf5")
		elif unit_type == "lytic": body_color = COLOR_BACTERIA
		draw_rect(Rect2(p + tail_offset - Vector2(2, 1), Vector2(4, 2)), body_color.darkened(0.35))
		var body_size := 8.0 if unit_type == "carrier" else 6.0
		draw_rect(Rect2(p - Vector2.ONE * body_size * 0.5, Vector2.ONE * body_size), body_color)
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), body_color.lightened(0.42))
		draw_rect(Rect2(p + Vector2(1, -2), Vector2(1, 1)), Color("ffffff"))
		if float(unit.get("cargo_organic", 0.0)) > 0.0005:
			draw_rect(Rect2(p + Vector2(4, 2), Vector2(3, 3)), COLOR_ORGANIC)
		if float(unit.get("cargo_mineral", 0.0)) > 0.0005:
			draw_rect(Rect2(p + Vector2(4, 2), Vector2(3, 3)), COLOR_MINERAL)
		if selected:
			draw_arc(p, 9.0, 0.0, TAU, 16, command_color, 1.0, false)


func _draw_world_fog(viewport: Vector2) -> void:
	var half_view := viewport / maxf(camera_zoom, 0.001) * 0.5
	var minimum := _exploration_coords(camera_center - half_view - Vector2.ONE * EXPLORATION_CELL_SIZE)
	var maximum := _exploration_coords(camera_center + half_view + Vector2.ONE * EXPLORATION_CELL_SIZE)
	var fog_color := Color(0.0, 0.004, 0.010, 0.965)
	var fog_size := Vector2.ONE * (EXPLORATION_CELL_SIZE * camera_zoom + 1.5)
	for cell_y in range(minimum.y, maximum.y + 1):
		for cell_x in range(minimum.x, maximum.x + 1):
			var cell := Vector2i(cell_x, cell_y)
			if explored_cells.has(_exploration_key(cell)):
				continue
			var world_top_left := Vector2(
				-WORLD_HALF + float(cell_x) * EXPLORATION_CELL_SIZE,
				-WORLD_HALF + float(cell_y) * EXPLORATION_CELL_SIZE
			)
			var screen_top_left := world_to_screen(world_top_left)
			draw_rect(Rect2(screen_top_left, fog_size), fog_color)


func _draw_expedition_selection() -> void:
	if not left_selecting or not left_dragged or upgrade_open or goals_open:
		return
	var selection_rect := _selection_rect(selection_start, selection_current)
	var color := Color(0.38, 1.0, 0.56, 0.88)
	draw_rect(selection_rect, Color(0.20, 0.86, 0.44, 0.08))
	draw_rect(selection_rect, color, false, 1.5)


func _draw_colony(_viewport: Vector2) -> void:
	for feeder in feeders:
		_draw_feeder(feeder)
	for segment in segments:
		_draw_hypha_segment(segment)
	for i in range(cores.size()):
		_draw_core(i)


func _draw_barracks_placement_preview() -> void:
	if mode != "place_barracks" or not _is_core_alive(selected_core):
		return
	var highlight := Color(0.38, 1.0, 0.56, 0.92)
	var valid_count := 0
	for segment in segments:
		if int(segment.get("core_id", -1)) != selected_core or bool(segment.get("orphaned", false)) or float(segment.get("growth", 0.0)) < 1.0:
			continue
		var tip: Vector2 = segment["b"]
		var too_close := false
		for core in cores:
			if tip.distance_to(core["pos"]) < 70.0:
				too_close = true
				break
		if too_close:
			continue
		valid_count += 1
		var p := _pixel_snap(world_to_screen(tip))
		var pulse := 10.0 + sin(sim_time * 5.0) * 2.0
		draw_arc(p, pulse, 0.0, TAU, 20, highlight, 2.0, false)
		draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), highlight, 1.0, false)
		draw_line(p + Vector2(0, -6), p + Vector2(0, 6), highlight, 1.0, false)
	if valid_count == 0:
		var viewport := get_viewport_rect().size
		_draw_label_box(Vector2(viewport.x * 0.5 - 110.0, 98.0), "暂无可用末端：请先延伸并等待主菌丝成熟", Color("76f5ca"))


func _draw_feeder(feeder: Dictionary) -> void:
	var resource := _resource_by_id(int(feeder["resource_id"]))
	if resource.is_empty() or not bool(resource["alive"]):
		return
	var a: Vector2 = feeder["a"]
	var full_b: Vector2 = feeder["b"]
	var b := a.lerp(full_b, float(feeder["growth"]))
	var delta := b - a
	var normal := Vector2(-delta.y, delta.x).normalized()
	var bend := sin(float(feeder["phase"])) * minf(7.0, delta.length() * 0.12)
	var world_points := PackedVector2Array([a, a.lerp(b, 0.38) + normal * bend, a.lerp(b, 0.72) - normal * bend * 0.45, b])
	var screen_points := PackedVector2Array()
	for point in world_points:
		screen_points.append(_pixel_snap(world_to_screen(point)))
	var feeder_color := Color(0.34, 0.72, 0.54, 0.72) if int(resource["kind"]) == 0 else Color(0.48, 0.64, 0.68, 0.78)
	draw_polyline(screen_points, feeder_color, 1.0, false)
	var resource_tip_color := COLOR_ORGANIC if int(resource["kind"]) == 0 else COLOR_MINERAL
	if float(feeder["growth"]) < 1.0:
		var tip := _pixel_snap(world_to_screen(b))
		draw_rect(Rect2(tip, Vector2(2, 2)), resource_tip_color)
	else:
		var tip := _pixel_snap(world_to_screen(full_b))
		draw_rect(Rect2(tip, Vector2(2, 2)), Color(resource_tip_color, 0.82))


func _draw_hypha_segment(segment: Dictionary) -> void:
	var a: Vector2 = segment["a"]
	var full_b: Vector2 = segment["b"]
	var growth := float(segment["growth"])
	var b := a.lerp(full_b, growth)
	var world_points := _curved_points(a, b, float(segment["curve"]) * growth)
	var screen_points := PackedVector2Array()
	for p in world_points:
		screen_points.append(_pixel_snap(world_to_screen(p)))
	if screen_points.size() < 2:
		return
	var viability := clampf(float(segment.get("viability", 1.0)), 0.0, 1.0)
	var orphaned := bool(segment.get("orphaned", false))
	var main_color := Color(0.58, 0.48, 0.42, 0.82 * viability) if orphaned else Color(COLOR_HYPHA, viability)
	# 总览层使用单像素网络；微观层保留三层像素菌丝质感。
	if camera_zoom < 0.12:
		draw_polyline(screen_points, Color(main_color.r, main_color.g, main_color.b, 0.88 * viability), 1.0, false)
	else:
		draw_polyline(screen_points, Color(0.04, 0.10 if orphaned else 0.18, 0.10, 0.95 * viability), maxf(2.0, roundf(5.0 * camera_zoom)), false)
		draw_polyline(screen_points, Color(0.42, 0.35, 0.30, viability) if orphaned else Color(0.32, 0.66, 0.49, viability), maxf(1.0, roundf(3.0 * camera_zoom)), false)
		draw_polyline(screen_points, main_color, 1.0, false)
	if growth < 1.0:
		var tip := _pixel_snap(world_to_screen(b))
		var tip_size := 6.0 if int(sim_time * 6.0) % 2 == 0 else 4.0
		draw_rect(Rect2(tip - Vector2.ONE * tip_size * 0.5, Vector2.ONE * tip_size), Color(0.78, 1.0, 0.82, 0.92))
	else:
		var tip := _pixel_snap(world_to_screen(full_b))
		draw_rect(Rect2(tip - Vector2(2, 2), Vector2(4, 4)), Color(0.72, 0.96, 0.78, 0.78))


func _curved_points(a: Vector2, b: Vector2, curve: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var delta := b - a
	var normal := Vector2(-delta.y, delta.x).normalized()
	var control := (a + b) * 0.5 + normal * delta.length() * curve
	for i in range(9):
		var t := i / 8.0
		var p := a * ((1.0 - t) * (1.0 - t)) + control * (2.0 * (1.0 - t) * t) + b * (t * t)
		points.append(p)
	return points


func _draw_core(core_id: int) -> void:
	var core = cores[core_id]
	var p := _pixel_snap(world_to_screen(core["pos"]))
	var cell := maxf(1.0, roundf(3.0 * camera_zoom))
	var alive := bool(core.get("alive", true))
	var is_barracks := String(core.get("kind", "normal")) == "barracks"
	if is_barracks and core_id == selected_core:
		var selected_radius := SCOUT_OPERATING_RADIUS if String(core.get("production_unit", "forager")) == "scout" else EXPEDITION_OPERATING_RADIUS
		draw_arc(p, selected_radius * camera_zoom, 0.0, TAU, 96, Color(0.36, 0.86, 0.96, 0.32) if selected_radius == SCOUT_OPERATING_RADIUS else Color(0.38, 1.0, 0.56, 0.28), 1.0, false)
	# 13×13 程序像素孢子：外缘、胞质和高光均由方格组成。
	for gy in range(-6, 7):
		for gx in range(-6, 7):
			var d := Vector2(gx, gy).length()
			if d > 6.25:
				continue
			var color := (Color("a7f4d7") if is_barracks else COLOR_CORE) if alive else Color("59636a")
			if d > 5.1:
				color = (Color("287b72") if is_barracks else Color("4d9d72")) if alive else Color("343d45")
			elif alive and gx <= -2 and gy <= -2:
				color = Color("ffffff")
			elif alive and ((gx == 2 and gy == -1) or (gx == -2 and gy == 2)):
				color = Color("397c62")
			var cell_pos := p + Vector2(gx, gy) * cell - Vector2.ONE * cell * 0.5
			draw_rect(Rect2(cell_pos, Vector2.ONE * cell), color)
	if is_barracks and alive:
		var emblem_color := Color("174d47")
		draw_rect(Rect2(p + Vector2(-4, -1), Vector2(8, 2)), emblem_color)
		draw_rect(Rect2(p + Vector2(-1, -4), Vector2(2, 8)), emblem_color)
	# 离散辉光像素，不使用模糊圆形光晕。
	if alive:
		var flicker := 1.0 if int(sim_time * 3.0 + float(core["pulse"])) % 2 == 0 else 0.55
		for offset in [Vector2(-9, -3), Vector2(8, -5), Vector2(-7, 7), Vector2(10, 4)]:
			var glow_pos: Vector2 = p + (offset as Vector2) * cell * 0.75
			draw_rect(Rect2(_pixel_snap(glow_pos), Vector2(2, 2)), Color(0.55, 0.95, 0.69, 0.22 * flicker))
	if float(core.get("toxin_pressure", 0.0)) > 0.0 and alive:
		draw_rect(Rect2(p + Vector2(-22, 1), Vector2(3, 3)), Color(0.72, 0.38, 0.88, 0.78))
		draw_rect(Rect2(p + Vector2(20, -7), Vector2(2, 2)), Color(0.72, 0.38, 0.88, 0.58))
	if not (core["jobs"] as Array).is_empty():
		var first_job = core["jobs"][0]
		var job_remaining := float(first_job.get("remaining", DNA_JOB_SECONDS)) if first_job is Dictionary else float(first_job)
		var job_total := float(first_job.get("total", DNA_JOB_SECONDS)) if first_job is Dictionary else DNA_JOB_SECONDS
		var progress := 1.0 - job_remaining / maxf(0.001, job_total)
		var bar := Rect2(p + Vector2(-18, -27), Vector2(36, 4))
		draw_rect(bar, Color("142a38"))
		draw_rect(Rect2(bar.position + Vector2.ONE, Vector2((bar.size.x - 2.0) * progress, 2)), COLOR_MINERAL)
	if is_barracks and not (core.get("spore_jobs", []) as Array).is_empty():
		var spore_job: Dictionary = (core.get("spore_jobs", []) as Array)[0]
		var spore_remaining := float(spore_job.get("remaining", EXPEDITION_SPORE_BUILD_SECONDS))
		var spore_total := float(spore_job.get("total", EXPEDITION_SPORE_BUILD_SECONDS))
		var spore_progress := 1.0 - spore_remaining / maxf(0.001, spore_total)
		var spore_bar := Rect2(p + Vector2(-18, -27), Vector2(36, 4))
		draw_rect(spore_bar, Color("102d2a"))
		draw_rect(Rect2(spore_bar.position + Vector2.ONE, Vector2((spore_bar.size.x - 2.0) * spore_progress, 2)), Color("76f5ca"))
	if core_id == selected_core:
		var s := 24.0 * camera_zoom
		var c := Color(0.75, 1.0, 0.85, 0.88)
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var corner := p + Vector2(sx, sy) * s
				draw_line(corner, corner - Vector2(sx * 7.0, 0), c, 2.0, false)
				draw_line(corner, corner - Vector2(0, sy * 7.0), c, 2.0, false)


func _pixel_snap(p: Vector2) -> Vector2:
	return Vector2(roundf(p.x / 2.0) * 2.0, roundf(p.y / 2.0) * 2.0)


func _draw_extension_preview() -> void:
	if mode != "extend":
		return
	var core_id := selected_tip_core if selected_tip_valid else selected_core
	if core_id < 0 or core_id >= cores.size():
		return
	var target: Vector2 = screen_to_world(last_mouse)
	var source: Vector2 = selected_tip if selected_tip_valid else _best_source(core_id, target)
	var vector: Vector2 = target - source
	var length: float = minf(vector.length(), _max_segment_length())
	var remaining: float = maxf(0.0, _hypha_capacity_for_core(core_id) - _core_hypha_length(core_id))
	length = minf(length, remaining)
	if vector.length() > 0.01:
		target = source + vector.normalized() * length
	var cost := int(ceil(length / ORGANIC_PER_LENGTH))
	var affordable: bool = organic >= cost and length >= MIN_SEGMENT_LENGTH
	var color: Color = Color(0.68, 0.95, 0.76, 0.76) if affordable else Color(0.95, 0.35, 0.38, 0.78)
	draw_dashed_line(_pixel_snap(world_to_screen(source)), _pixel_snap(world_to_screen(target)), color, 2.0, 8.0, false)
	var source_screen := _pixel_snap(world_to_screen(source))
	draw_rect(Rect2(source_screen - Vector2(3, 3), Vector2(6, 6)), color)
	var label_pos := world_to_screen(target) + Vector2(14, -8)
	_draw_label_box(label_pos, "%d μm　" % int(round(length / 2.0)) + "● %d" % cost, color)


func _draw_hud(viewport: Vector2) -> void:
	_draw_top_resources()
	_draw_minimap(viewport)
	_draw_scale(viewport)
	_draw_speed_controls(viewport)
	_draw_upgrade_hud(viewport)
	_draw_goals_hud(viewport)
	_draw_ecology_event_hud(viewport)
	_draw_help(viewport)


func _draw_top_resources() -> void:
	var panel := Rect2(18, 16, 708, 48)
	draw_style_box(_panel_style(), panel)
	var x := 36.0
	_draw_resource_readout(Vector2(x, 47), COLOR_WATER, "水分  ∞")
	x += 132
	_draw_resource_readout(Vector2(x, 47), COLOR_ORGANIC, "有机营养  %.3f" % organic)
	x += 224
	_draw_resource_readout(Vector2(x, 47), COLOR_MINERAL, "矿物  %.3f" % mineral)
	x += 184
	_draw_resource_readout(Vector2(x, 47), Color("75e6c0"), "DNA  %d" % dna)


func _draw_resource_readout(pos: Vector2, color: Color, text_value: String) -> void:
	draw_rect(Rect2(_pixel_snap(pos + Vector2(-3, -9)), Vector2(6, 6)), color)
	draw_string(fallback_font, pos + Vector2(11, 0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _minimap_rect() -> Rect2:
	var viewport := get_viewport_rect().size
	return Rect2(viewport.x - 230.0, 18.0, 208.0, 176.0)


func _draw_minimap(_viewport: Vector2) -> void:
	var rect := _minimap_rect()
	draw_style_box(_panel_style(), rect)
	var inner := rect.grow(-10.0)
	draw_rect(inner, Color("06101f"))
	var minimap_cell_size := inner.size / float(EXPLORATION_GRID_SIDE)
	for explored_key in explored_cells:
		var key := int(explored_key)
		var cell := Vector2i(key % EXPLORATION_GRID_SIDE, int(key / EXPLORATION_GRID_SIDE))
		var cell_position := inner.position + Vector2(float(cell.x), float(cell.y)) * minimap_cell_size
		draw_rect(Rect2(cell_position, minimap_cell_size + Vector2.ONE), Color("0b2940"))
	# 先标出异常富集区，再绘制资源点；热点不再被均匀噪声淹没。
	for hotspot in resource_hotspots:
		if not bool(hotspot["anomalous"]):
			continue
		if not discovered_hotspots.has(String(hotspot.get("id", ""))):
			continue
		var hp := _pixel_snap(_world_to_minimap(hotspot["pos"], inner))
		var hc := COLOR_ORGANIC if int(hotspot["kind"]) == 0 else COLOR_MINERAL
		draw_rect(Rect2(hp - Vector2(4, 4), Vector2(9, 9)), Color(hc.r, hc.g, hc.b, 0.20))
		draw_rect(Rect2(hp - Vector2(1, 1), Vector2(3, 3)), Color(hc.r, hc.g, hc.b, 0.72))
		draw_line(hp + Vector2(-5, 0), hp + Vector2(5, 0), Color(hc, 0.72), 1.0, false)
		draw_line(hp + Vector2(0, -5), hp + Vector2(0, 5), Color(hc, 0.72), 1.0, false)
	var ecology_event := _current_ecology_event()
	if not ecology_event.is_empty() and _is_world_explored(ecology_event["pos"]):
		var ep := _pixel_snap(_world_to_minimap(ecology_event["pos"], inner))
		var event_color := Color("f4ca83") if String(ecology_event.get("phase", "warning")) == "warning" else (Color("ff789f") if String(ecology_event.get("type", "bloom")) == "bloom" else Color("b884ec"))
		draw_rect(Rect2(ep - Vector2(4, 4), Vector2(9, 9)), Color(event_color, 0.18))
		draw_line(ep + Vector2(-5, -5), ep + Vector2(5, 5), Color(event_color, 0.92), 1.0, false)
		draw_line(ep + Vector2(5, -5), ep + Vector2(-5, 5), Color(event_color, 0.92), 1.0, false)
	for i in range(0, resources.size(), 3):
		var resource = resources[i]
		if not bool(resource["alive"]):
			continue
		if not _is_world_explored(resource["pos"]):
			continue
		var p := _world_to_minimap(resource["pos"], inner)
		var color := Color(COLOR_ORGANIC, 0.55) if int(resource["kind"]) == 0 else Color(COLOR_MINERAL, 0.72)
		var size := 1.0 if int(resource["kind"]) == 0 else 2.0
		draw_rect(Rect2(_pixel_snap(p), Vector2(size, size)), color)
	for i in range(0, bacteria.size(), 3):
		if not _is_world_explored(bacteria[i]["pos"]):
			continue
		var bp := _pixel_snap(_world_to_minimap(bacteria[i]["pos"], inner))
		draw_rect(Rect2(bp, Vector2(1, 1)), Color(COLOR_BACTERIA, 0.82))
	for segment in segments:
		if not _is_world_explored(segment["a"]):
			continue
		var a := _world_to_minimap(segment["a"], inner)
		var b_world: Vector2 = (segment["a"] as Vector2).lerp(segment["b"], float(segment["growth"]))
		var b := _world_to_minimap(b_world, inner)
		draw_line(a, b, Color(0.61, 0.95, 0.72, 0.62), 1.0)
	for core in cores:
		var cp := _pixel_snap(_world_to_minimap(core["pos"], inner))
		var core_color := Color("76f5ca") if String(core.get("kind", "normal")) == "barracks" else COLOR_CORE
		draw_rect(Rect2(cp - Vector2(2, 2), Vector2(5, 5)), core_color)
	for unit in expedition_units:
		var up := _pixel_snap(_world_to_minimap(unit["pos"], inner))
		var unit_color := Color("5edcf5") if String(unit.get("unit_type", "forager")) == "scout" else Color("76f5ca")
		draw_rect(Rect2(up, Vector2(2, 2)), Color("56f08d") if selected_expedition_ids.has(int(unit.get("id", -1))) else unit_color)
	var world_view_size := get_viewport_rect().size / camera_zoom
	var top_left := camera_center - world_view_size * 0.5
	var bottom_right := camera_center + world_view_size * 0.5
	top_left.x = clampf(top_left.x, -WORLD_HALF, WORLD_HALF)
	top_left.y = clampf(top_left.y, -WORLD_HALF, WORLD_HALF)
	bottom_right.x = clampf(bottom_right.x, -WORLD_HALF, WORLD_HALF)
	bottom_right.y = clampf(bottom_right.y, -WORLD_HALF, WORLD_HALF)
	var view_rect := Rect2(_world_to_minimap(top_left, inner), _world_to_minimap(bottom_right, inner) - _world_to_minimap(top_left, inner))
	draw_rect(view_rect, Color(0.72, 0.95, 0.92, 0.82), false, 1.2)
	draw_string(fallback_font, rect.position + Vector2(12, 22), "探索 %.1f%%　发现 %d" % [_explored_fraction() * 100.0, _discovered_hotspot_count()], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _world_to_minimap(p: Vector2, rect: Rect2) -> Vector2:
	var uv := (p + Vector2(WORLD_HALF, WORLD_HALF)) / (WORLD_HALF * 2.0)
	return rect.position + uv * rect.size


func _draw_scale(viewport: Vector2) -> void:
	var micrometers := 50.0
	var label := "50 μm"
	if camera_zoom < 0.06:
		micrometers = 5000.0
		label = "5 mm"
	elif camera_zoom < 0.18:
		micrometers = 500.0
		label = "500 μm"
	var world_length := micrometers * 2.0
	var pixels := world_length * camera_zoom
	var start := Vector2(28, viewport.y - 34)
	draw_line(start, start + Vector2(pixels, 0), COLOR_TEXT, 2.0)
	draw_line(start, start + Vector2(0, -6), COLOR_TEXT, 2.0)
	draw_line(start + Vector2(pixels, 0), start + Vector2(pixels, -6), COLOR_TEXT, 2.0)
	draw_string(fallback_font, start + Vector2(0, -11), label, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _speed_rects() -> Array:
	var viewport := get_viewport_rect().size
	var base := Vector2(viewport.x - 242.0, viewport.y - 52.0)
	return [
		{"rect": Rect2(base, Vector2(62, 32)), "speed": 1.0},
		{"rect": Rect2(base + Vector2(68, 0), Vector2(62, 32)), "speed": 10.0},
		{"rect": Rect2(base + Vector2(136, 0), Vector2(62, 32)), "speed": 60.0}
	]


func _draw_speed_controls(_viewport: Vector2) -> void:
	for item in _speed_rects():
		var active := is_equal_approx(sim_speed, float(item["speed"]))
		var rect: Rect2 = item["rect"]
		draw_style_box(_rounded_style(Color(0.17, 0.48, 0.41, 0.90) if active else COLOR_PANEL, Color(0.55, 0.88, 0.72, 0.75) if active else COLOR_BORDER, 6, 1), rect)
		draw_string(fallback_font, rect.position + Vector2(18, 22), "%d×" % int(item["speed"]), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _speed_button_at(pos: Vector2) -> float:
	for item in _speed_rects():
		if (item["rect"] as Rect2).has_point(pos):
			return float(item["speed"])
	return 0.0


func _upgrade_hud_rect() -> Rect2:
	return Rect2(18, 76, 122, 32)


func _draw_upgrade_hud(_viewport: Vector2) -> void:
	var rect := _upgrade_hud_rect()
	draw_style_box(_rounded_style(Color(0.04, 0.14, 0.18, 0.94), Color(COLOR_ORGANIC, 0.78), 7, 2), rect)
	draw_string(fallback_font, rect.position + Vector2(15, 21), "升级 [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC)


func _goals_hud_rect() -> Rect2:
	return Rect2(18, 116, 122, 32)


func _draw_goals_hud(_viewport: Vector2) -> void:
	var ready := 0
	for goal in _goal_definitions():
		if _goal_complete(goal["id"]) and not bool(goals_claimed.get(goal["id"], false)):
			ready += 1
	var rect := _goals_hud_rect()
	draw_style_box(_rounded_style(Color(0.04, 0.12, 0.18, 0.94), Color(COLOR_MINERAL, 0.78), 7, 2), rect)
	var label := "目标 [G]" if ready == 0 else "目标 [G]  %d" % ready
	draw_string(fallback_font, rect.position + Vector2(13, 21), label, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MINERAL)


func _ecology_event_hud_rect() -> Rect2:
	var viewport := get_viewport_rect().size
	return Rect2(viewport.x - 230.0, 202.0, 208.0, 66.0)


func _draw_ecology_event_hud(_viewport: Vector2) -> void:
	var event := _current_ecology_event()
	if event.is_empty():
		return
	var rect := _ecology_event_hud_rect()
	var event_type := String(event.get("type", "bloom"))
	var warning := String(event.get("phase", "warning")) == "warning"
	var accent := Color("f4ca83") if warning else (Color("ff789f") if event_type == "bloom" else Color("b884ec"))
	var hovered := rect.has_point(last_mouse)
	draw_style_box(_rounded_style(Color(0.08, 0.08, 0.12, 0.97) if hovered else Color(0.035, 0.075, 0.11, 0.96), Color(accent, 0.92), 8, 2), rect)
	var phase_text := "预警" if warning else "活跃"
	var seconds_left := ceili(float(event.get("remaining", 0.0)))
	draw_string(fallback_font, rect.position + Vector2(12, 23), "%s · %s" % [_ecology_event_name(event_type), phase_text], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, accent)
	var detail := "点击定位　%02d:%02d" % [seconds_left / 60, seconds_left % 60]
	if not warning and event_type == "bloom":
		detail = "局部细菌 %d　%02d:%02d" % [_count_event_bacteria(int(event.get("id", -1))), seconds_left / 60, seconds_left % 60]
	draw_string(fallback_font, rect.position + Vector2(12, 49), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _goal_definitions() -> Array:
	return [
		{"id": "first_hypha", "title": "初次萌发", "desc": "形成第一段主菌丝", "reward": {"organic": 25.0}, "reward_text": "有机营养 +25.000"},
		{"id": "mineral_trace", "title": "矿物脉络", "desc": "累计吸收 1.000 矿物离子", "reward": {"mineral": 5.0}, "reward_text": "矿物离子 +5.000"},
		{"id": "second_core", "title": "双核心网络", "desc": "形成第二个孢子核心", "reward": {"dna": 2}, "reward_text": "DNA +2"},
		{"id": "network_1mm", "title": "一毫米网络", "desc": "主菌丝总长度达到 1000 μm", "reward": {"organic": 80.0, "mineral": 8.0}, "reward_text": "有机 +80.000　矿物 +8.000"},
		{"id": "primary_diet", "title": "确立主食性", "desc": "解锁第一条生物食性", "reward": {"dna": 3}, "reward_text": "DNA +3"},
		{"id": "bacterial_bloom", "title": "培养皿中的新生命", "desc": "观察累计25次细菌分裂", "reward": {"mineral": 3.0}, "reward_text": "矿物离子 +3.000"},
		{"id": "first_bacterium", "title": "首次微型捕食", "desc": "完整消化第一个细菌", "reward": {"organic": 20.0}, "reward_text": "有机营养 +20.000"},
		{"id": "bacteria_control", "title": "菌落控制", "desc": "累计完整消化25个细菌", "reward": {"dna": 3}, "reward_text": "DNA +3"},
		{"id": "first_structure", "title": "结构突变", "desc": "购买第一级通用结构进化", "reward": {"organic": 40.0}, "reward_text": "有机营养 +40.000"},
		{"id": "bacteria_specialist", "title": "细菌专家", "desc": "将任一细菌专属组件升至3级", "reward": {"dna": 4, "mineral": 2.0}, "reward_text": "DNA +4　矿物 +2.000"},
		{"id": "culture_survey", "title": "培养环境勘探", "desc": "永久记录3处异常资源区", "reward": {"dna": 2}, "reward_text": "DNA +2"},
		{"id": "expedition_supply", "title": "远征补给线", "desc": "体外部队累计带回10.000有机与0.500矿物", "reward": {"dna": 1, "mineral": 2.0}, "reward_text": "DNA +1　矿物 +2.000"},
		{"id": "expedition_control", "title": "主动菌落压制", "desc": "体外部队累计消灭10个细菌", "reward": {"dna": 3, "organic": 30.0}, "reward_text": "DNA +3　有机 +30.000"},
		{"id": "ecology_response", "title": "生态应答", "desc": "成功应对1次细菌生态事件", "reward": {"dna": 2, "mineral": 2.0}, "reward_text": "DNA +2　矿物 +2.000"}
	]


func _total_hypha_length() -> float:
	var total := 0.0
	for segment in segments:
		total += (segment["b"] as Vector2).distance_to(segment["a"])
	return total


func _goal_complete(goal_id: String) -> bool:
	match goal_id:
		"first_hypha":
			return segments.size() >= 1
		"mineral_trace":
			return lifetime_mineral_absorbed >= 1.0
		"second_core":
			return cores.size() >= 2
		"network_1mm":
			return _total_hypha_length() >= 2000.0
		"primary_diet":
			return diet_order.size() >= 1
		"bacterial_bloom":
			return lifetime_bacteria_births >= 25
		"first_bacterium":
			return lifetime_bacteria_consumed >= 1
		"bacteria_control":
			return lifetime_bacteria_consumed >= 25
		"first_structure":
			return _total_structure_levels() >= 1
		"bacteria_specialist":
			return _max_bacteria_component_level() >= 3
		"culture_survey":
			return _discovered_hotspot_count() >= 3
		"expedition_supply":
			return lifetime_expedition_organic_returned >= 10.0 and lifetime_expedition_mineral_returned >= 0.5
		"expedition_control":
			return lifetime_expedition_bacteria_killed >= 10
		"ecology_response":
			return lifetime_ecology_events_contained >= 1
	return false


func _goal_progress_text(goal_id: String) -> String:
	match goal_id:
		"first_hypha":
			return "%d / 1" % mini(segments.size(), 1)
		"mineral_trace":
			return "%.3f / 1.000" % minf(lifetime_mineral_absorbed, 1.0)
		"second_core":
			return "%d / 2" % mini(cores.size(), 2)
		"network_1mm":
			return "%.0f / 1000 μm" % minf(_total_hypha_length() / 2.0, 1000.0)
		"primary_diet":
			return "%d / 1" % mini(diet_order.size(), 1)
		"bacterial_bloom":
			return "%d / 25" % mini(lifetime_bacteria_births, 25)
		"first_bacterium":
			return "%d / 1" % mini(lifetime_bacteria_consumed, 1)
		"bacteria_control":
			return "%d / 25" % mini(lifetime_bacteria_consumed, 25)
		"first_structure":
			return "%d / 1" % mini(_total_structure_levels(), 1)
		"bacteria_specialist":
			return "%d / 3" % mini(_max_bacteria_component_level(), 3)
		"culture_survey":
			return "%d / 3 处" % mini(_discovered_hotspot_count(), 3)
		"expedition_supply":
			return "有机 %.3f/10.000　矿物 %.3f/0.500" % [minf(lifetime_expedition_organic_returned, 10.0), minf(lifetime_expedition_mineral_returned, 0.5)]
		"expedition_control":
			return "%d / 10" % mini(lifetime_expedition_bacteria_killed, 10)
		"ecology_response":
			return "%d / 1" % mini(lifetime_ecology_events_contained, 1)
	return ""


func _total_structure_levels() -> int:
	var total := 0
	for structure_id in STRUCTURE_IDS:
		total += int(structure_levels.get(structure_id, 0))
	return total


func _max_bacteria_component_level() -> int:
	var highest := 0
	for component_id in BACTERIA_COMPONENT_IDS:
		highest = maxi(highest, int(bacteria_components.get(component_id, 0)))
	return highest


func _claim_goal(goal_id: String) -> void:
	if bool(goals_claimed.get(goal_id, false)) or not _goal_complete(goal_id):
		return
	for goal in _goal_definitions():
		if goal["id"] != goal_id:
			continue
		var reward: Dictionary = goal["reward"]
		organic += float(reward.get("organic", 0.0))
		mineral += float(reward.get("mineral", 0.0))
		dna += int(reward.get("dna", 0))
		goals_claimed[goal_id] = true
		toast("目标奖励已领取：%s" % goal["reward_text"], 4.0)
		return


func _goals_panel_rect(viewport: Vector2) -> Rect2:
	var size := Vector2(minf(840.0, viewport.x - 100.0), minf(570.0, viewport.y - 80.0))
	return Rect2(_pixel_snap((viewport - size) * 0.5), size)


func _goal_button_rect(panel: Rect2, index: int) -> Rect2:
	return Rect2(panel.position + Vector2(panel.size.x - 144, 102 + index * 84), Vector2(108, 32))


func _goal_prev_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.position + Vector2(panel.size.x * 0.5 - 116, panel.size.y - 42), Vector2(96, 28))


func _goal_next_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.position + Vector2(panel.size.x * 0.5 + 20, panel.size.y - 42), Vector2(96, 28))


func _handle_goals_click(pos: Vector2) -> void:
	var panel := _goals_panel_rect(get_viewport_rect().size)
	var close_rect := Rect2(panel.end - Vector2(54, panel.size.y - 20), Vector2(34, 28))
	if close_rect.has_point(pos):
		goals_open = false
		return
	var goals := _goal_definitions()
	var page_count := maxi(1, int(ceil(float(goals.size()) / GOALS_PER_PAGE)))
	if _goal_prev_rect(panel).has_point(pos):
		goal_page = posmod(goal_page - 1, page_count)
		return
	if _goal_next_rect(panel).has_point(pos):
		goal_page = posmod(goal_page + 1, page_count)
		return
	goal_page = clampi(goal_page, 0, page_count - 1)
	var start := goal_page * GOALS_PER_PAGE
	var finish := mini(start + GOALS_PER_PAGE, goals.size())
	for goal_index in range(start, finish):
		var local_index := goal_index - start
		if _goal_button_rect(panel, local_index).has_point(pos):
			_claim_goal(goals[goal_index]["id"])
			return


func _draw_goals_panel(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.015, 0.03, 0.80))
	var panel := _goals_panel_rect(viewport)
	draw_style_box(_rounded_style(Color(0.018, 0.06, 0.095, 0.99), Color(COLOR_MINERAL, 0.78), 12, 2), panel)
	draw_string(fallback_font, panel.position + Vector2(32, 38), "长期目标", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	draw_string(fallback_font, panel.position + Vector2(156, 38), "不同目标提供不同奖励", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	var close_rect := Rect2(panel.end - Vector2(54, panel.size.y - 20), Vector2(34, 28))
	draw_style_box(_rounded_style(Color(0.08, 0.12, 0.16, 1.0), COLOR_BORDER, 6, 2), close_rect)
	draw_string(fallback_font, close_rect.position + Vector2(12, 19), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	var goals := _goal_definitions()
	var page_count := maxi(1, int(ceil(float(goals.size()) / GOALS_PER_PAGE)))
	goal_page = clampi(goal_page, 0, page_count - 1)
	draw_string(fallback_font, panel.position + Vector2(panel.size.x - 144, 38), "%d / %d 页" % [goal_page + 1, page_count], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	var start := goal_page * GOALS_PER_PAGE
	var finish := mini(start + GOALS_PER_PAGE, goals.size())
	for goal_index in range(start, finish):
		var i := goal_index - start
		var goal: Dictionary = goals[goal_index]
		var card := Rect2(panel.position + Vector2(28, 82 + i * 84), Vector2(panel.size.x - 56, 70))
		var complete := _goal_complete(goal["id"])
		var claimed := bool(goals_claimed.get(goal["id"], false))
		var accent := COLOR_HYPHA if complete else COLOR_BORDER
		draw_style_box(_rounded_style(Color(0.025, 0.095, 0.125, 0.96), Color(accent, 0.72), 9, 2), card)
		draw_string(fallback_font, card.position + Vector2(16, 24), goal["title"], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
		draw_string(fallback_font, card.position + Vector2(16, 49), goal["desc"], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		draw_string(fallback_font, card.position + Vector2(300, 24), _goal_progress_text(goal["id"]), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
		draw_string(fallback_font, card.position + Vector2(300, 49), goal["reward_text"], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC if goal["reward"].has("organic") else COLOR_MINERAL)
		var button := _goal_button_rect(panel, i)
		var button_bg := Color(0.08, 0.23, 0.18, 1.0) if complete and not claimed else Color(0.05, 0.075, 0.09, 1.0)
		draw_style_box(_rounded_style(button_bg, Color(COLOR_HYPHA, 0.82) if complete and not claimed else COLOR_BORDER, 7, 2), button)
		var button_text := "已领取" if claimed else ("领取" if complete else "进行中")
		draw_string(fallback_font, button.position + Vector2(22, 21), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if complete and not claimed else COLOR_MUTED)
	for nav in [[_goal_prev_rect(panel), "上一页"], [_goal_next_rect(panel), "下一页"]]:
		var nav_rect: Rect2 = nav[0]
		draw_style_box(_rounded_style(Color(0.05, 0.11, 0.15, 1.0), COLOR_BORDER, 6, 2), nav_rect)
		draw_string(fallback_font, nav_rect.position + Vector2(18, 19), nav[1], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _upgrade_panel_rect(viewport: Vector2) -> Rect2:
	var size := Vector2(minf(920.0, viewport.x - 80.0), minf(570.0, viewport.y - 80.0))
	return Rect2(_pixel_snap((viewport - size) * 0.5), size)


func _upgrade_tab_rects(panel: Rect2) -> Array:
	var start := panel.position + Vector2(34, 76)
	var result: Array = []
	for i in range(5):
		result.append(Rect2(start + Vector2(i * 128.0, 0), Vector2(120, 34)))
	return result


func _upgrade_close_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.end - Vector2(54, panel.size.y - 20), Vector2(34, 28))


func _upgrade_node_button_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.position + Vector2(382, 418), Vector2(156, 42))


func _survival_panel_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.position + Vector2(580, 132), Vector2(panel.size.x - 614, 342))


func _survival_button_rect(panel: Rect2, index: int) -> Rect2:
	var side := _survival_panel_rect(panel)
	return Rect2(side.position + Vector2(side.size.x - 102, 50 + index * 70), Vector2(88, 28))


func _diet_card_rect(panel: Rect2, index: int) -> Rect2:
	var column := index % 2
	var row := index / 2
	var width := (panel.size.x - 88.0) * 0.5
	return Rect2(panel.position + Vector2(34 + column * (width + 20.0), 132 + row * 172.0), Vector2(width, 154))


func _diet_button_rect(panel: Rect2, index: int) -> Rect2:
	var card := _diet_card_rect(panel, index)
	return Rect2(card.end - Vector2(142, 44), Vector2(124, 30))


func _diet_components_button_rect(panel: Rect2, index: int) -> Rect2:
	var card := _diet_card_rect(panel, index)
	return Rect2(card.position + Vector2(144, 110), Vector2(106, 30))


func _bacteria_components_back_rect(panel: Rect2) -> Rect2:
	return Rect2(panel.position + Vector2(panel.size.x - 148, 76), Vector2(114, 34))


func _diet_detail_tab_rect(panel: Rect2, index: int) -> Rect2:
	return Rect2(panel.position + Vector2(34 + index * 132, 118), Vector2(122, 30))


func _diet_special_unit_button_rect(panel: Rect2, index: int) -> Rect2:
	return Rect2(panel.position + Vector2(panel.size.x - 184, 174 + index * 112), Vector2(134, 34))


func _bacteria_component_button_rect(panel: Rect2, index: int) -> Rect2:
	return Rect2(panel.position + Vector2(panel.size.x - 182, 174 + index * 112), Vector2(132, 34))


func _structure_card_rect(panel: Rect2, index: int) -> Rect2:
	var column := index % 2
	var row: int = index / 2
	var width := (panel.size.x - 88.0) * 0.5
	return Rect2(panel.position + Vector2(34 + column * (width + 20.0), 132 + row * 172.0), Vector2(width, 154))


func _structure_button_rect(panel: Rect2, index: int) -> Rect2:
	var card := _structure_card_rect(panel, index)
	return Rect2(card.end - Vector2(142, 44), Vector2(124, 30))


func _barracks_unit_card_rect(panel: Rect2, index: int) -> Rect2:
	return _structure_card_rect(panel, index)


func _barracks_unit_button_rect(panel: Rect2, index: int) -> Rect2:
	return _structure_button_rect(panel, index)


func _scout_upgrade_button_rect(panel: Rect2, upgrade_id: String) -> Rect2:
	var card := _barracks_unit_card_rect(panel, BARRACK_UNIT_IDS.find("scout"))
	if upgrade_id == "vision":
		return Rect2(card.position + Vector2(18, card.size.y - 44), Vector2(124, 30))
	return Rect2(card.end - Vector2(142, 44), Vector2(124, 30))


func _handle_upgrade_click(pos: Vector2) -> void:
	var panel := _upgrade_panel_rect(get_viewport_rect().size)
	if _upgrade_close_rect(panel).has_point(pos):
		upgrade_open = false
		return
	var tabs := _upgrade_tab_rects(panel)
	for i in range(tabs.size()):
		if (tabs[i] as Rect2).has_point(pos):
			upgrade_tab = i
			diet_detail_id = ""
			diet_detail_tab = 0
			return
	if upgrade_tab == 0 and _upgrade_node_button_rect(panel).has_point(pos):
		_upgrade_feeder_range(upgrade_core_id)
		return
	if upgrade_tab == 0:
		for i in range(SURVIVAL_IDS.size()):
			if _survival_button_rect(panel, i).has_point(pos):
				_purchase_survival(SURVIVAL_IDS[i])
				return
	if upgrade_tab == 1:
		if diet_detail_id != "":
			if _bacteria_components_back_rect(panel).has_point(pos):
				diet_detail_id = ""
				return
			if diet_detail_id == "bacteria":
				for detail_tab in range(2):
					if _diet_detail_tab_rect(panel, detail_tab).has_point(pos):
						diet_detail_tab = detail_tab
						return
			if diet_detail_id == "bacteria" and diet_detail_tab == 0:
				for i in range(BACTERIA_COMPONENT_IDS.size()):
					if _bacteria_component_button_rect(panel, i).has_point(pos):
						_purchase_bacteria_component(BACTERIA_COMPONENT_IDS[i])
						return
			else:
				var special_units: Array = DIET_SPECIAL_UNITS.get(diet_detail_id, [])
				for i in range(special_units.size()):
					if _diet_special_unit_button_rect(panel, i).has_point(pos):
						_purchase_diet_unit(diet_detail_id, String((special_units[i] as Dictionary).get("id", "")))
						return
			return
		for i in range(DIET_IDS.size()):
			if int(diet_levels.get(DIET_IDS[i], 0)) > 0 and _diet_components_button_rect(panel, i).has_point(pos):
				diet_detail_id = DIET_IDS[i]
				diet_detail_tab = 1
				return
			if _diet_button_rect(panel, i).has_point(pos):
				_purchase_diet(DIET_IDS[i])
				return
	if upgrade_tab == 2:
		for i in range(STRUCTURE_IDS.size()):
			if _structure_button_rect(panel, i).has_point(pos):
				_purchase_structure(STRUCTURE_IDS[i])
				return
	if upgrade_tab == 3:
		if bool(barracks_unit_unlocks.get("scout", false)):
			for scout_upgrade_id in SCOUT_UPGRADE_IDS:
				if _scout_upgrade_button_rect(panel, scout_upgrade_id).has_point(pos):
					_purchase_scout_upgrade(scout_upgrade_id)
					return
		for i in range(BARRACK_UNIT_IDS.size()):
			if _barracks_unit_button_rect(panel, i).has_point(pos):
				_purchase_barracks_unit(BARRACK_UNIT_IDS[i])
				return


func _draw_upgrade_panel(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.0, 0.015, 0.03, 0.80))
	var panel := _upgrade_panel_rect(viewport)
	draw_style_box(_rounded_style(Color(0.018, 0.065, 0.095, 0.99), Color(0.38, 0.78, 0.68, 0.88), 12, 2), panel)
	draw_string(fallback_font, panel.position + Vector2(34, 39), "进化与结构", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	draw_string(fallback_font, panel.position + Vector2(174, 39), "DNA %d" % dna, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MINERAL)
	draw_string(fallback_font, panel.position + Vector2(292, 39), "模拟继续运行", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	var close_rect := _upgrade_close_rect(panel)
	draw_style_box(_rounded_style(Color(0.08, 0.12, 0.16, 1.0), COLOR_BORDER, 6, 2), close_rect)
	draw_string(fallback_font, close_rect.position + Vector2(12, 19), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	var tab_names := ["自身能力", "食性", "结构", "兵营", "环境适应"]
	var tabs := _upgrade_tab_rects(panel)
	for i in range(tabs.size()):
		var tab_rect: Rect2 = tabs[i]
		var active := upgrade_tab == i
		draw_style_box(_rounded_style(Color(0.11, 0.30, 0.28, 0.96) if active else Color(0.025, 0.10, 0.14, 0.96), Color(0.52, 0.91, 0.72, 0.90) if active else COLOR_BORDER, 7, 2), tab_rect)
		draw_string(fallback_font, tab_rect.position + Vector2(18, 22), tab_names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if active else COLOR_MUTED)
	if upgrade_tab == 0:
		_draw_node_upgrade_card(panel)
	elif upgrade_tab == 1:
		if diet_detail_id != "":
			_draw_diet_detail(panel)
		else:
			_draw_diet_upgrade_cards(panel)
	elif upgrade_tab == 2:
		_draw_structure_upgrade_cards(panel)
	elif upgrade_tab == 3:
		_draw_barracks_upgrade_cards(panel)
	else:
		_draw_upgrade_placeholders(panel, "实验室环境无需气候适应；该分页留给后续章节")


func _draw_node_upgrade_card(panel: Rect2) -> void:
	upgrade_core_id = clampi(upgrade_core_id, 0, max(0, cores.size() - 1))
	var card := Rect2(panel.position + Vector2(34, 132), Vector2(520, 342))
	draw_style_box(_rounded_style(Color(0.025, 0.105, 0.13, 0.98), Color(COLOR_ORGANIC, 0.72), 10, 2), card)
	var level := int(cores[upgrade_core_id].get("feeder_range_level", 0))
	var range_um := _feeder_range_for_core(upgrade_core_id) / 2.0
	draw_string(fallback_font, card.position + Vector2(22, 34), "吸收节点　Lv.%d / %d" % [level, MAX_FEEDER_RANGE_LEVEL], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC)
	draw_string(fallback_font, card.position + Vector2(22, 70), "孢子核心 %d" % (upgrade_core_id + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	draw_string(fallback_font, card.position + Vector2(22, 104), "细菌丝范围　%.0f μm" % range_um, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	draw_string(fallback_font, card.position + Vector2(22, 136), "DNA 生产速度　+%d%%" % int(_dna_speed_bonus(upgrade_core_id) * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	draw_string(fallback_font, card.position + Vector2(22, 168), "单次 DNA 时间　%.1f 秒" % _dna_job_duration(upgrade_core_id), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	draw_string(fallback_font, card.position + Vector2(22, 210), "每级：范围 +12 μm，DNA 速度 +15%", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	draw_string(fallback_font, card.position + Vector2(22, 242), "升级只消耗有机营养，不消耗 DNA", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	var button := _upgrade_node_button_rect(panel)
	var maxed := level >= MAX_FEEDER_RANGE_LEVEL
	draw_style_box(_rounded_style(Color(0.08, 0.22, 0.18, 1.0) if not maxed else Color(0.06, 0.08, 0.10, 1.0), Color(COLOR_ORGANIC, 0.88) if not maxed else COLOR_MUTED, 8, 2), button)
	var button_text := "已满级" if maxed else "强化  %.3f" % _feeder_upgrade_cost(upgrade_core_id)
	draw_string(fallback_font, button.position + Vector2(17, 27), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if not maxed else COLOR_MUTED)
	var side := _survival_panel_rect(panel)
	draw_style_box(_rounded_style(Color(0.02, 0.08, 0.11, 0.94), COLOR_BORDER, 10, 2), side)
	draw_string(fallback_font, side.position + Vector2(16, 28), "核心生存进化", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	for i in range(SURVIVAL_IDS.size()):
		var survival_id: String = SURVIVAL_IDS[i]
		var survival_level := int(survival_levels.get(survival_id, 0))
		var row := Rect2(side.position + Vector2(12, 42 + i * 70), Vector2(side.size.x - 24, 62))
		draw_style_box(_rounded_style(Color(0.035, 0.10, 0.125, 0.96), Color(COLOR_HYPHA, 0.48), 7, 1), row)
		draw_string(fallback_font, row.position + Vector2(10, 20), "%s　%d/4" % [SURVIVAL_NAMES[survival_id], survival_level], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
		var effect_text := ""
		match survival_id:
			"wall":
				effect_text = "核心上限 %.3f" % _core_max_biomass_value()
			"detox":
				effect_text = "毒素伤害 %d%%" % int(_toxin_damage_multiplier() * 100.0)
			"repair":
				effect_text = "自然 %.3f　储备 %.3f" % [_passive_recovery_rate(), _repair_recovery_rate()]
			"storage":
				effect_text = "每次储备 %.3f" % _repair_reserve_purchase_amount()
		draw_string(fallback_font, row.position + Vector2(10, 45), effect_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		var survival_button := _survival_button_rect(panel, i)
		var survival_maxed := survival_level >= 4
		draw_style_box(_rounded_style(Color(0.07, 0.20, 0.17, 1.0) if not survival_maxed else Color(0.05, 0.07, 0.09, 1.0), Color(COLOR_ORGANIC, 0.78) if not survival_maxed else COLOR_MUTED, 6, 1), survival_button)
		var survival_button_text := "已满" if survival_maxed else "%d DNA" % _survival_cost(survival_id)
		draw_string(fallback_font, survival_button.position + Vector2(12, 19), survival_button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if not survival_maxed else COLOR_MUTED)


func _draw_diet_upgrade_cards(panel: Rect2) -> void:
	for i in range(DIET_IDS.size()):
		var diet_id: String = DIET_IDS[i]
		var card := _diet_card_rect(panel, i)
		var level := int(diet_levels.get(diet_id, 0))
		var unlocked := level > 0
		var accent := COLOR_ORGANIC if unlocked else COLOR_BORDER
		draw_style_box(_rounded_style(Color(0.025, 0.10, 0.125, 0.98), Color(accent, 0.82), 10, 2), card)
		draw_string(fallback_font, card.position + Vector2(18, 28), DIET_NAMES[diet_id], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
		draw_string(fallback_font, card.position + Vector2(18, 53), DIET_TARGETS[diet_id], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		if unlocked:
			var order_index := diet_order.find(diet_id) + 1
			draw_string(fallback_font, card.position + Vector2(18, 82), "第 %d 食性　Lv.%d / 5" % [order_index, level], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC)
			draw_string(fallback_font, card.position + Vector2(18, 108), "吸收效率　%d%%" % int(_diet_efficiency(diet_id) * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
			var components_button := _diet_components_button_rect(panel, i)
			var detail_color := COLOR_BACTERIA if diet_id == "bacteria" else COLOR_ORGANIC
			draw_style_box(_rounded_style(Color(0.08, 0.15, 0.23, 1.0), Color(detail_color, 0.82), 7, 2), components_button)
			draw_string(fallback_font, components_button.position + Vector2(13, 20), "专属升级", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, detail_color)
		else:
			draw_string(fallback_font, card.position + Vector2(18, 86), "尚未确立　新食性成本按十倍增长", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		var button := _diet_button_rect(panel, i)
		var maxed := level >= 5
		draw_style_box(_rounded_style(Color(0.07, 0.20, 0.17, 1.0) if not maxed else Color(0.05, 0.07, 0.09, 1.0), Color(COLOR_ORGANIC, 0.86) if not maxed else COLOR_MUTED, 7, 2), button)
		var button_text := "已满级" if maxed else ("升级 %d DNA" % _diet_level_cost(diet_id) if unlocked else "确立 %d DNA" % _diet_unlock_cost())
		draw_string(fallback_font, button.position + Vector2(10, 20), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if not maxed else COLOR_MUTED)
	draw_string(fallback_font, panel.position + Vector2(34, 512), "腐生始终是实验室阶段的基础能力；食性决定未来可利用的生物对象。", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _draw_diet_detail(panel: Rect2) -> void:
	var back := _bacteria_components_back_rect(panel)
	draw_style_box(_rounded_style(Color(0.05, 0.10, 0.14, 1.0), COLOR_BORDER, 7, 2), back)
	draw_string(fallback_font, back.position + Vector2(20, 22), "返回食性", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	if diet_detail_id == "bacteria":
		for i in range(2):
			var tab_rect := _diet_detail_tab_rect(panel, i)
			var active := diet_detail_tab == i
			draw_style_box(_rounded_style(Color(0.10, 0.24, 0.22, 1.0) if active else Color(0.04, 0.10, 0.14, 1.0), Color(COLOR_BACTERIA, 0.82) if active else COLOR_BORDER, 6, 1), tab_rect)
			draw_string(fallback_font, tab_rect.position + Vector2(15, 20), "能力组件" if i == 0 else "专属兵种", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if active else COLOR_MUTED)
	else:
		var tab_rect := _diet_detail_tab_rect(panel, 0)
		draw_style_box(_rounded_style(Color(0.10, 0.24, 0.22, 1.0), Color(COLOR_ORGANIC, 0.82), 6, 1), tab_rect)
		draw_string(fallback_font, tab_rect.position + Vector2(15, 20), "专属兵种", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	if diet_detail_id == "bacteria" and diet_detail_tab == 0:
		_draw_bacteria_components(panel)
	else:
		_draw_diet_special_units(panel, diet_detail_id)


func _draw_bacteria_components(panel: Rect2) -> void:
	for i in range(BACTERIA_COMPONENT_IDS.size()):
		var component_id: String = BACTERIA_COMPONENT_IDS[i]
		var level := int(bacteria_components.get(component_id, 0))
		var card := Rect2(panel.position + Vector2(34, 164 + i * 112), Vector2(panel.size.x - 68, 96))
		draw_style_box(_rounded_style(Color(0.035, 0.095, 0.125, 0.98), Color(COLOR_BACTERIA, 0.66), 9, 2), card)
		draw_string(fallback_font, card.position + Vector2(18, 28), "%s　Lv.%d / 3" % [BACTERIA_COMPONENT_NAMES[component_id], level], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
		draw_string(fallback_font, card.position + Vector2(18, 56), BACTERIA_COMPONENT_DESCRIPTIONS[component_id], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		var effect_text := ""
		match component_id:
			"trap":
				effect_text = "捕获距离 %.0f μm" % (_bacteria_capture_radius() / 2.0)
			"enzymes":
				effect_text = "消化速度 ×%.2f" % _bacteria_digestion_multiplier()
			"antibiotic":
				effect_text = "抑制半径 %.0f μm　细菌速度 %d%%" % [_antibiotic_radius() / 2.0, int(_antibiotic_bacteria_multiplier() * 100.0)] if level > 0 else "尚未形成抑菌区"
		draw_string(fallback_font, card.position + Vector2(430, 56), effect_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC)
		var button := _bacteria_component_button_rect(panel, i)
		var maxed := level >= 3
		draw_style_box(_rounded_style(Color(0.08, 0.22, 0.18, 1.0) if not maxed else Color(0.05, 0.07, 0.09, 1.0), Color(COLOR_BACTERIA, 0.84) if not maxed else COLOR_MUTED, 7, 2), button)
		var button_text := "已满级" if maxed else "进化 %d DNA" % _bacteria_component_cost(component_id)
		draw_string(fallback_font, button.position + Vector2(13, 22), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if not maxed else COLOR_MUTED)
	draw_string(fallback_font, panel.position + Vector2(34, 510), "三个组件可以并行升级；抗生素会同时减慢细菌吸收与分裂冷却。", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _draw_diet_special_units(panel: Rect2, diet_id: String) -> void:
	var units: Array = DIET_SPECIAL_UNITS.get(diet_id, [])
	for i in range(units.size()):
		var item: Dictionary = units[i]
		var unit_id := String(item.get("id", ""))
		var unlocked := bool(diet_unit_unlocks.get(unit_id, false))
		var available := bool(item.get("available", false))
		var card := Rect2(panel.position + Vector2(34, 164 + i * 112), Vector2(panel.size.x - 68, 96))
		var accent := COLOR_BACTERIA if diet_id == "bacteria" else COLOR_ORGANIC
		draw_style_box(_rounded_style(Color(0.035, 0.095, 0.125, 0.98), Color(accent, 0.66 if available else 0.34), 9, 2), card)
		draw_string(fallback_font, card.position + Vector2(18, 28), String(item.get("name", unit_id)), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if available else COLOR_MUTED)
		draw_string(fallback_font, card.position + Vector2(18, 56), String(item.get("desc", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		var requirement := "解锁后进入兵营生产列表" if available else String(item.get("requirement", "后续开放"))
		draw_string(fallback_font, card.position + Vector2(430, 56), requirement, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, accent if available else COLOR_MUTED)
		var button := _diet_special_unit_button_rect(panel, i)
		var button_color := accent if available and not unlocked else COLOR_MUTED
		draw_style_box(_rounded_style(Color(0.07, 0.20, 0.17, 1.0) if available and not unlocked else Color(0.05, 0.07, 0.09, 1.0), Color(button_color, 0.82), 7, 2), button)
		var button_text := "已解锁" if unlocked else ("解锁 %d DNA" % int(item.get("cost", 0)) if available else "尚未开放")
		draw_string(fallback_font, button.position + Vector2(12, 22), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if available and not unlocked else COLOR_MUTED)
	draw_string(fallback_font, panel.position + Vector2(34, 510), "%s专属部队只会在确立对应食性后出现，并受该食性效率加成。" % DIET_NAMES.get(diet_id, "该食性"), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _draw_barracks_upgrade_cards(panel: Rect2) -> void:
	for i in range(BARRACK_UNIT_IDS.size()):
		var unit_id: String = BARRACK_UNIT_IDS[i]
		var unlocked := bool(barracks_unit_unlocks.get(unit_id, false))
		var available := true
		var card := _barracks_unit_card_rect(panel, i)
		var accent := Color("76f5ca") if unlocked else COLOR_BORDER
		draw_style_box(_rounded_style(Color(0.025, 0.10, 0.125, 0.98), Color(accent, 0.82), 10, 2), card)
		draw_string(fallback_font, card.position + Vector2(18, 28), BARRACK_UNIT_NAMES[unit_id], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if available else COLOR_MUTED)
		draw_string(fallback_font, card.position + Vector2(18, 55), BARRACK_UNIT_DESCRIPTIONS[unit_id], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		var stat_text := "已掌握，可在兵营切换" if unlocked else "解锁后进入所有兵营"
		if unit_id == "scout" and unlocked:
			stat_text = "感知 Lv.%d　运动 Lv.%d　视野 %.0f μm" % [int(scout_upgrade_levels.get("vision", 0)), int(scout_upgrade_levels.get("speed", 0)), _scout_reveal_radius() / 2.0]
		draw_string(fallback_font, card.position + Vector2(18, 88), stat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC if unlocked else COLOR_MUTED)
		if unit_id == "scout" and unlocked:
			for scout_upgrade_id in SCOUT_UPGRADE_IDS:
				var scout_level := int(scout_upgrade_levels.get(scout_upgrade_id, 0))
				var scout_maxed := scout_level >= MAX_SCOUT_UPGRADE_LEVEL
				var scout_button := _scout_upgrade_button_rect(panel, scout_upgrade_id)
				draw_style_box(_rounded_style(Color(0.07, 0.20, 0.17, 1.0) if not scout_maxed else Color(0.05, 0.07, 0.09, 1.0), Color(Color("5edcf5"), 0.82) if not scout_maxed else COLOR_BORDER, 7, 2), scout_button)
				var scout_button_text := "已满级" if scout_maxed else "%s %d DNA" % [SCOUT_UPGRADE_NAMES[scout_upgrade_id], _scout_upgrade_cost(scout_upgrade_id)]
				draw_string(fallback_font, scout_button.position + Vector2(9, 20), scout_button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if not scout_maxed else COLOR_MUTED)
			continue
		var button := _barracks_unit_button_rect(panel, i)
		draw_style_box(_rounded_style(Color(0.07, 0.20, 0.17, 1.0) if available and not unlocked else Color(0.05, 0.07, 0.09, 1.0), Color(Color("76f5ca"), 0.82) if available and not unlocked else COLOR_BORDER, 7, 2), button)
		var button_text := "已掌握" if unlocked else ("解锁 %d DNA" % int(BARRACK_UNIT_UNLOCK_COSTS.get(unit_id, 0)) if available else "尚未开放")
		draw_string(fallback_font, button.position + Vector2(10, 20), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if available and not unlocked else COLOR_MUTED)
	draw_string(fallback_font, panel.position + Vector2(34, 512), "通用兵种在此解锁；食性特攻部队位于各食性的“专属升级”页面。", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _draw_structure_upgrade_cards(panel: Rect2) -> void:
	for i in range(STRUCTURE_IDS.size()):
		var structure_id: String = STRUCTURE_IDS[i]
		var level := int(structure_levels.get(structure_id, 0))
		var card := _structure_card_rect(panel, i)
		draw_style_box(_rounded_style(Color(0.025, 0.10, 0.125, 0.98), Color(COLOR_HYPHA, 0.72), 10, 2), card)
		draw_string(fallback_font, card.position + Vector2(18, 28), "%s　Lv.%d / 4" % [STRUCTURE_NAMES[structure_id], level], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
		draw_string(fallback_font, card.position + Vector2(18, 55), STRUCTURE_DESCRIPTIONS[structure_id], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
		var effect_text := ""
		match structure_id:
			"branching":
				effect_text = "每个核心容量　%.0f μm" % (_hypha_capacity_for_core(0) / 2.0)
			"elongation":
				effect_text = "单段上限　%.0f μm" % (_max_segment_length() / 2.0)
			"feeders":
				effect_text = "同时吸收　%d 条" % _active_feeder_capacity()
			"growth":
				effect_text = "生长时间　%.1f 秒" % _hypha_growth_seconds()
		draw_string(fallback_font, card.position + Vector2(18, 88), effect_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC)
		var button := _structure_button_rect(panel, i)
		var maxed := level >= 4
		draw_style_box(_rounded_style(Color(0.07, 0.20, 0.17, 1.0) if not maxed else Color(0.05, 0.07, 0.09, 1.0), Color(COLOR_HYPHA, 0.86) if not maxed else COLOR_MUTED, 7, 2), button)
		var button_text := "已满级" if maxed else "进化 %d DNA" % _structure_cost(structure_id)
		draw_string(fallback_font, button.position + Vector2(10, 20), button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if not maxed else COLOR_MUTED)
	draw_string(fallback_font, panel.position + Vector2(34, 512), "结构升级对所有孢子核心生效，同一阶段内可以继续追加等级。", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _draw_upgrade_placeholders(panel: Rect2, message: String) -> void:
	var card := Rect2(panel.position + Vector2(34, 132), Vector2(panel.size.x - 68, 342))
	draw_style_box(_rounded_style(Color(0.02, 0.08, 0.11, 0.94), COLOR_BORDER, 10, 2), card)
	draw_string(fallback_font, card.position + Vector2(26, 42), "分页已建立", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	draw_string(fallback_font, card.position + Vector2(26, 82), message, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _draw_help(viewport: Vector2) -> void:
	var text_value := "左键点击/拖框选兵　右键指令/拖动地图　滚轮缩放　F5 保存"
	draw_string(fallback_font, Vector2(viewport.x * 0.5 - 220.0, viewport.y - 20.0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color(COLOR_MUTED, 0.78))
	if not selected_expedition_ids.is_empty():
		var selected_text := "体外部队　已选 %d / %d" % [selected_expedition_ids.size(), expedition_units.size()]
		var rect := Rect2(22, viewport.y - 86, 198, 34)
		draw_style_box(_rounded_style(Color(0.025, 0.11, 0.11, 0.94), Color(0.38, 1.0, 0.56, 0.72), 7, 1), rect)
		draw_string(fallback_font, rect.position + Vector2(12, 22), selected_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("baffd0"))


func _draw_bacteria_tooltip() -> void:
	var bacterium := _bacterium_at(last_mouse)
	if bacterium.is_empty():
		return
	var stored := float(bacterium.get("stored", 0.0))
	var strain := String(bacterium.get("strain", "normal"))
	var bacteria_name := "暴发型细菌" if strain == "bloom" else "静止细菌"
	var behavior_text := "生态事件中的高活性局部菌群" if strain == "bloom" else "原地吸收并分裂扩张"
	var lines := [
		bacteria_name,
		behavior_text,
		"吸收 %.3f/秒　真菌初始速率的 1/20" % BACTERIA_ABSORB_RATE,
		"分裂营养 %.3f / %.3f" % [stored, BACTERIA_DIVISION_NUTRIENT],
		"自身基因组复制　不消耗真菌 DNA"
	]
	var max_width := 0.0
	for line in lines:
		max_width = maxf(max_width, fallback_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE).x)
	var size := Vector2(max_width + 28.0, 18.0 + lines.size() * 22.0)
	var viewport := get_viewport_rect().size
	var pos := last_mouse + Vector2(18, 14)
	pos.x = clampf(pos.x, 12.0, viewport.x - size.x - 12.0)
	pos.y = clampf(pos.y, 70.0, viewport.y - size.y - 12.0)
	var rect := Rect2(_pixel_snap(pos), size)
	draw_style_box(_rounded_style(Color(0.075, 0.035, 0.075, 0.98), Color(COLOR_BACTERIA, 0.88), 8, 2), rect)
	for i in range(lines.size()):
		draw_string(fallback_font, rect.position + Vector2(14, 24 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT if i == 0 else COLOR_MUTED)


func _draw_core_tooltip() -> bool:
	var core_id := _core_at(last_mouse)
	if core_id < 0:
		return false
	var core: Dictionary = cores[core_id]
	var maximum := maxf(0.001, float(core.get("max_biomass", CORE_MAX_BIOMASS)))
	var percent := clampf(float(core.get("biomass", maximum)) / maximum * 100.0, 0.0, 100.0)
	var core_name := "兵营核心" if String(core.get("kind", "normal")) == "barracks" else "孢子核心"
	var text_value := "%s %d　生物量 %.1f%%" % [core_name, core_id + 1, percent]
	var size := fallback_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE) + Vector2(28.0, 18.0)
	var viewport := get_viewport_rect().size
	var pos := last_mouse + Vector2(18, 14)
	pos.x = clampf(pos.x, 12.0, viewport.x - size.x - 12.0)
	pos.y = clampf(pos.y, 70.0, viewport.y - size.y - 12.0)
	var rect := Rect2(_pixel_snap(pos), size)
	draw_style_box(_rounded_style(Color(0.025, 0.095, 0.105, 0.98), Color("75e6a8"), 7, 1), rect)
	draw_string(fallback_font, rect.position + Vector2(14, 22), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	return true


func _bacterium_at(screen_pos: Vector2) -> Dictionary:
	if camera_zoom < 0.12:
		return {}
	var best: Dictionary = {}
	var best_distance := 9.0
	for bacterium in bacteria:
		if not _is_world_explored(bacterium["pos"]):
			continue
		var distance := screen_pos.distance_to(world_to_screen(bacterium["pos"]))
		if distance <= best_distance:
			best_distance = distance
			best = bacterium
	return best


func _current_menu_buttons() -> Array:
	var result: Array = []
	if selected_core >= 0 and selected_core < cores.size() and mode == "normal":
		var center := world_to_screen(cores[selected_core]["pos"])
		var range_level := int(cores[selected_core].get("feeder_range_level", 0))
		var current_range_um := _feeder_range_for_core(selected_core) / 2.0
		var is_barracks := String(cores[selected_core].get("kind", "normal")) == "barracks"
		var production_unit := String(cores[selected_core].get("production_unit", "forager"))
		if not _available_barracks_units().has(production_unit):
			production_unit = "forager"
		var production_name := String(BARRACK_UNIT_NAMES.get(production_unit, "游猎孢子"))
		var production_cost_text := "有机 %.3f\n矿物 %.3f" % [float(UNIT_ORGANIC_COSTS.get(production_unit, EXPEDITION_SPORE_ORGANIC_COST)), float(UNIT_MINERAL_COSTS.get(production_unit, EXPEDITION_SPORE_MINERAL_COST))]
		var upgrade_cost_text := "已达到当前上限" if range_level >= MAX_FEEDER_RANGE_LEVEL else "范围 %.0f → %.0f μm\nDNA 速度 +%d%% → +%d%%\n有机营养 %.3f" % [current_range_um, current_range_um + FEEDER_RANGE_PER_LEVEL / 2.0, int(_dna_speed_bonus(selected_core) * 100.0), int((_dna_speed_bonus(selected_core) + DNA_SPEED_BONUS_PER_NODE_LEVEL) * 100.0), _feeder_upgrade_cost(selected_core)]
		var specs := [
			[Vector2(-90, -34), "延伸", "extend_core", COLOR_HYPHA, "延伸主菌丝", "有机营养 1.000 / 11 μm\n最终消耗按长度向上取整"],
			[Vector2(-34, -92), "生产" if is_barracks else "DNA", "queue_spore" if is_barracks else "dna", COLOR_MINERAL, "生产%s　%.1f 秒" % [production_name, float(UNIT_BUILD_SECONDS.get(production_unit, EXPEDITION_SPORE_BUILD_SECONDS))] if is_barracks else "生产 1 DNA　%.1f 秒" % _dna_job_duration(selected_core), production_cost_text if is_barracks else "有机营养 30.000\n矿物离子 1.000"],
			[Vector2(34, -92), "强化", "upgrade_feeder_range", COLOR_ORGANIC, "增强细菌丝延展范围　Lv.%d" % range_level, upgrade_cost_text],
			[Vector2(90, -34), "状态", "status", COLOR_WATER, "查看核心状态", "不消耗资源"],
			[Vector2(90, 34), "修复", "repair_core", Color("ff9f8f"), "添加缓慢修复储备", "储备最多 +%.3f\n恢复速度 %.3f / 秒\n有机营养 %.3f" % [_repair_reserve_purchase_amount(), _repair_recovery_rate(), CORE_REPAIR_ORGANIC_COST]],
			[Vector2(34, 92), "切换" if is_barracks else "兵营", "cycle_spore_unit" if is_barracks else "barracks_mode", Color("76f5ca"), "当前兵种：%s" % production_name if is_barracks else "选择菌丝末端建造兵营", "点击切换已解锁兵种\n商店 → 兵营/食性专属升级" if is_barracks else "有机 %.3f\n矿物 %.3f\nDNA %d" % [BARRACKS_ORGANIC_COST, BARRACKS_MINERAL_COST, BARRACKS_DNA_COST]]
		]
		for i in range(specs.size()):
			var progress := clampf(menu_anim * 1.35 - i * 0.12, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - progress, 3.0)
			result.append({"pos": _pixel_snap(center + specs[i][0] * eased), "origin": _pixel_snap(center), "radius": 25.0 * progress, "label": specs[i][1], "action": specs[i][2], "color": specs[i][3], "alpha": progress, "tooltip_title": specs[i][4], "tooltip_cost": specs[i][5]})
	elif selected_tip_valid and mode == "normal":
		var center := world_to_screen(selected_tip)
		var specs := [
			[Vector2(-62, -52), "延伸", "extend_tip", COLOR_HYPHA, "继续延伸主菌丝", "有机营养 1.000 / 11 μm\n最终消耗按长度向上取整"],
			[Vector2(0, -88), "核心", "new_core", COLOR_ORGANIC, "形成次级孢子核心", "有机营养 70.000\n矿物离子 6.000"],
			[Vector2(62, -52), "兵营", "new_barracks", Color("7bd6a3"), "形成兵营核心", "有机 %.3f\n矿物 %.3f\nDNA %d" % [BARRACKS_ORGANIC_COST, BARRACKS_MINERAL_COST, BARRACKS_DNA_COST]]
		]
		for i in range(specs.size()):
			var progress := clampf(menu_anim * 1.4 - i * 0.14, 0.0, 1.0)
			var eased := 1.0 - pow(1.0 - progress, 3.0)
			result.append({"pos": _pixel_snap(center + specs[i][0] * eased), "origin": _pixel_snap(center), "radius": 23.0 * progress, "label": specs[i][1], "action": specs[i][2], "color": specs[i][3], "alpha": progress, "tooltip_title": specs[i][4], "tooltip_cost": specs[i][5]})
	return result


func _draw_selection_menu() -> void:
	var hovered: Dictionary = {}
	for button in _current_menu_buttons():
		var p: Vector2 = button["pos"]
		var radius := float(button["radius"])
		if radius < 3.0:
			continue
		var color: Color = button["color"]
		var alpha := float(button["alpha"])
		var origin: Vector2 = button["origin"]
		draw_line(origin, p, Color(color.r, color.g, color.b, 0.34 * alpha), 2.0, false)
		var rect := Rect2(_pixel_snap(p - Vector2.ONE * radius), Vector2.ONE * radius * 2.0)
		draw_style_box(_rounded_style(Color(0.025, 0.09, 0.13, 0.96 * alpha), Color(color.r, color.g, color.b, 0.82 * alpha), 8, 2), rect)
		var label: String = button["label"]
		var width := fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE).x
		draw_string(fallback_font, _pixel_snap(p + Vector2(-width * 0.5, 5)), label, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color(COLOR_TEXT, alpha))
		if alpha >= 0.82 and last_mouse.distance_to(p) <= radius:
			hovered = button
	if not hovered.is_empty():
		_draw_menu_tooltip(hovered)


func _draw_menu_tooltip(button: Dictionary) -> void:
	var lines := [String(button["tooltip_title"])]
	lines.append_array(String(button["tooltip_cost"]).split("\n"))
	var max_width := 0.0
	for line in lines:
		max_width = maxf(max_width, fallback_font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE).x)
	var size := Vector2(max_width + 28.0, 18.0 + lines.size() * 22.0)
	var viewport := get_viewport_rect().size
	var pos := last_mouse + Vector2(18, 14)
	pos.x = clampf(pos.x, 12.0, viewport.x - size.x - 12.0)
	pos.y = clampf(pos.y, 70.0, viewport.y - size.y - 12.0)
	var rect := Rect2(_pixel_snap(pos), size)
	draw_style_box(_rounded_style(Color(0.018, 0.055, 0.085, 0.98), Color(button["color"], 0.88), 8, 2), rect)
	for i in range(lines.size()):
		var color := COLOR_TEXT if i == 0 else COLOR_MUTED
		draw_string(fallback_font, rect.position + Vector2(14, 24 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, color)


func _draw_status_panel(viewport: Vector2) -> void:
	var core = cores[selected_core]
	var is_barracks := String(core.get("kind", "normal")) == "barracks"
	var rect := Rect2(22, 82, 350, 282)
	draw_style_box(_panel_style(), rect)
	draw_string(fallback_font, rect.position + Vector2(16, 28), "%s %d" % ["兵营核心" if is_barracks else "孢子核心", selected_core + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("a7f4d7") if is_barracks else COLOR_TEXT)
	var biomass_percent := float(core.get("biomass", CORE_MAX_BIOMASS)) / maxf(0.001, float(core.get("max_biomass", CORE_MAX_BIOMASS))) * 100.0
	draw_string(fallback_font, rect.position + Vector2(16, 57), "生物量　%.1f%%" % biomass_percent, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("ff9f9f"))
	draw_string(fallback_font, rect.position + Vector2(16, 82), "修复储备　%.3f　(+%.3f / 秒)" % [float(core.get("repair_reserve", 0.0)), _repair_recovery_rate()], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("ffbd9f"))
	draw_string(fallback_font, rect.position + Vector2(16, 107), "毒素伤害　%.3f / 秒" % float(core.get("toxin_pressure", 0.0)), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("c794e8"))
	draw_string(fallback_font, rect.position + Vector2(16, 132), "营生方式　腐生", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	draw_string(fallback_font, rect.position + Vector2(16, 157), "菌丝长度　%d / %d μm" % [int(_core_hypha_length(selected_core) / 2.0), int(_hypha_capacity_for_core(selected_core) / 2.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	var queue_text := "%s队列　%d / 10" % [BARRACK_UNIT_NAMES.get(String(core.get("production_unit", "forager")), "游猎孢子"), (core.get("spore_jobs", []) as Array).size()] if is_barracks else "DNA 队列　%d" % (core["jobs"] as Array).size()
	draw_string(fallback_font, rect.position + Vector2(16, 182), queue_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	draw_string(fallback_font, rect.position + Vector2(16, 207), "水分供应　稳定（无限）", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_WATER)
	draw_string(fallback_font, rect.position + Vector2(16, 232), "细菌丝范围　%.0f μm　Lv.%d" % [_feeder_range_for_core(selected_core) / 2.0, int(core.get("feeder_range_level", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_ORGANIC)
	var barracks_radius := SCOUT_OPERATING_RADIUS if String(core.get("production_unit", "forager")) == "scout" else EXPEDITION_OPERATING_RADIUS
	var final_text := "活动半径　%.0f μm　体外部队 %d / %d" % [barracks_radius / 2.0, expedition_units.size(), MAX_EXPEDITION_SPORES] if is_barracks else "DNA 速度　+%d%%　%.1f 秒/点" % [int(_dna_speed_bonus(selected_core) * 100.0), _dna_job_duration(selected_core)]
	draw_string(fallback_font, rect.position + Vector2(16, 257), final_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("76f5ca") if is_barracks else COLOR_MINERAL)
	if viewport.x < 800:
		return


func _draw_game_over(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.01, 0.01, 0.025, 0.78))
	var rect := Rect2(_pixel_snap(viewport * 0.5 - Vector2(220, 92)), Vector2(440, 184))
	draw_style_box(_rounded_style(Color(0.055, 0.035, 0.055, 0.98), Color("c77888"), 12, 2), rect)
	draw_string(fallback_font, rect.position + Vector2(32, 48), "菌落失活", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("ff9f9f"))
	draw_string(fallback_font, rect.position + Vector2(32, 86), "所有孢子核心的生物量均已归零", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)
	draw_string(fallback_font, rect.position + Vector2(32, 120), "模拟已暂停；重新开始功能将在存档界面加入", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)


func _draw_discovery_banner(viewport: Vector2) -> void:
	var width := minf(540.0, viewport.x - 80.0)
	var rect := Rect2(_pixel_snap(Vector2(viewport.x * 0.5 - width * 0.5, 124.0)), Vector2(width, 74.0))
	var pulse := 0.72 + sin(sim_time * 3.5) * 0.12
	draw_style_box(_rounded_style(Color(0.018, 0.11, 0.15, 0.98), Color(0.36, 0.86, 0.96, pulse), 10, 2), rect)
	draw_rect(Rect2(rect.position + Vector2(16, 17), Vector2(8, 8)), Color("5edcf5"))
	draw_rect(Rect2(rect.position + Vector2(19, 14), Vector2(2, 14)), Color("bdf7ff"))
	draw_string(fallback_font, rect.position + Vector2(36, 29), discovery_banner_title, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("bdf7ff"))
	draw_string(fallback_font, rect.position + Vector2(36, 55), discovery_banner_detail, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _draw_ecology_banner(viewport: Vector2) -> void:
	var width := minf(620.0, viewport.x - 80.0)
	var rect := Rect2(_pixel_snap(Vector2(viewport.x * 0.5 - width * 0.5, 206.0)), Vector2(width, 74.0))
	var pulse := 0.70 + sin(sim_time * 4.0) * 0.16
	draw_style_box(_rounded_style(Color(0.095, 0.035, 0.075, 0.98), Color(0.94, 0.45, 0.62, pulse), 10, 2), rect)
	draw_rect(Rect2(rect.position + Vector2(17, 15), Vector2(8, 8)), Color("ff789f"))
	draw_rect(Rect2(rect.position + Vector2(20, 12), Vector2(2, 14)), Color("ffd2dc"))
	draw_string(fallback_font, rect.position + Vector2(38, 29), ecology_banner_title, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("ffd2dc"))
	draw_string(fallback_font, rect.position + Vector2(38, 55), ecology_banner_detail, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _draw_toast(viewport: Vector2) -> void:
	var width := fallback_font.get_string_size(toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE).x + 34.0
	var rect := Rect2(viewport.x * 0.5 - width * 0.5, 78, width, 38)
	draw_style_box(_panel_style(), rect)
	draw_string(fallback_font, rect.position + Vector2(17, 25), toast_text, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _offline_report_panel_rect(viewport: Vector2) -> Rect2:
	var size := Vector2(minf(700.0, viewport.x - 48.0), minf(500.0, viewport.y - 48.0))
	return Rect2(_pixel_snap(viewport * 0.5 - size * 0.5), size)


func _offline_report_button_rect(viewport: Vector2) -> Rect2:
	var panel := _offline_report_panel_rect(viewport)
	return Rect2(_pixel_snap(Vector2(panel.get_center().x - 92.0, panel.end.y - 62.0)), Vector2(184.0, 38.0))


func _draw_offline_report(viewport: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, viewport), Color(0.005, 0.015, 0.025, 0.82))
	var panel := _offline_report_panel_rect(viewport)
	draw_style_box(_rounded_style(Color(0.018, 0.075, 0.095, 0.99), Color("55d9a5"), 14, 2), panel)
	draw_string(fallback_font, panel.position + Vector2(28, 38), "休眠培养报告", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("bfffe1"))
	var actual_seconds := float(offline_report.get("actual_seconds", 0.0))
	var settled_seconds := float(offline_report.get("settled_seconds", 0.0))
	var cap_note := "　已触发 2 小时上限" if bool(offline_report.get("capped", false)) else ""
	draw_string(fallback_font, panel.position + Vector2(28, 68), "离开 %s　·　结算 %s%s" % [_format_duration(actual_seconds), _format_duration(settled_seconds), cap_note], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	draw_line(panel.position + Vector2(28, 82), Vector2(panel.end.x - 28, panel.position.y + 82), Color(COLOR_BORDER, 0.72), 1.0)

	var left_x := panel.position.x + 30.0
	var right_x := panel.position.x + panel.size.x * 0.53
	var first_y := panel.position.y + 116.0
	var row_gap := 28.0
	var left_lines := [
		["真实采集", Color("84f2bd")],
		["细菌丝有机　+%.3f" % float(offline_report.get("absorbed_organic", 0.0)), COLOR_ORGANIC],
		["细菌丝矿物　+%.3f" % float(offline_report.get("absorbed_mineral", 0.0)), COLOR_MINERAL],
		["远征有机　　+%.3f" % float(offline_report.get("returned_organic", 0.0)), COLOR_ORGANIC],
		["远征矿物　　+%.3f" % float(offline_report.get("returned_mineral", 0.0)), COLOR_MINERAL],
		["余额变化　有机 %+.3f　矿物 %+.3f" % [float(offline_report.get("organic_delta", 0.0)), float(offline_report.get("mineral_delta", 0.0))], COLOR_TEXT]
	]
	var right_lines := [
		["成长与探索", Color("84f2bd")],
		["DNA 完成　+%d" % int(offline_report.get("dna_completed", 0)), Color("75e6c0")],
		["体外单位　+%d" % int(offline_report.get("units_built", 0)), Color("76f5ca")],
		["探索格　　+%d　（%+.2f%%）" % [int(offline_report.get("explored_cells", 0)), float(offline_report.get("explored_percent", 0.0))], Color("5edcf5")],
		["异常区　　+%d" % int(offline_report.get("hotspots", 0)), Color("8ce9ff")],
		["细菌出生 %d　消灭 %d" % [int(offline_report.get("bacteria_births", 0)), int(offline_report.get("bacteria_consumed", 0))], COLOR_BACTERIA]
	]
	for i in range(left_lines.size()):
		draw_string(fallback_font, Vector2(left_x, first_y + i * row_gap), String(left_lines[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, left_lines[i][1])
	for i in range(right_lines.size()):
		draw_string(fallback_font, Vector2(right_x, first_y + i * row_gap), String(right_lines[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, right_lines[i][1])

	var biomass_delta := float(offline_report.get("biomass_delta", 0.0))
	var living_before := int(offline_report.get("living_cores_before", 0))
	var living_after := int(offline_report.get("living_cores_after", 0))
	draw_string(fallback_font, panel.position + Vector2(30, 304), "核心生物量变化　%+.3f　·　存活核心 %d → %d" % [biomass_delta, living_before, living_after], HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("ffbd9f") if biomass_delta < 0.0 else COLOR_TEXT)
	draw_string(fallback_font, panel.position + Vector2(30, 338), "结算仅消耗真实资源；生态事件离线冻结，普通敌害最多推进 1 分钟。", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_MUTED)
	if bool(offline_report.get("capped", false)):
		draw_string(fallback_font, panel.position + Vector2(30, 366), "超过两小时的休眠时间不会产生额外收益或伤害。", HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, Color("f4ca83"))
	var button := _offline_report_button_rect(viewport)
	var hovered := button.has_point(last_mouse)
	draw_style_box(_rounded_style(Color(0.10, 0.34, 0.27, 0.98) if hovered else Color(0.035, 0.16, 0.16, 0.98), Color("68efad") if hovered else COLOR_BORDER, 8, 2), button)
	var label := "返回培养皿"
	var label_width := fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	draw_string(fallback_font, Vector2(button.get_center().x - label_width * 0.5, button.position.y + 25.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_TEXT)


func _close_offline_report() -> void:
	offline_report_open = false
	queue_redraw()


func _draw_label_box(pos: Vector2, text_value: String, color: Color) -> void:
	var size := fallback_font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE)
	var rect := Rect2(pos - Vector2(7, 19), size + Vector2(14, 10))
	draw_style_box(_rounded_style(Color(0.018, 0.06, 0.09, 0.91), Color(color.r, color.g, color.b, 0.62), 5, 1), rect)
	draw_string(fallback_font, pos, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, UI_FONT_SIZE, COLOR_TEXT)


func _panel_style() -> StyleBoxFlat:
	return _rounded_style(COLOR_PANEL, COLOR_BORDER, 8, 1)


func _rounded_style(background: Color, border: Color, radius: int, border_width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func toast(message: String, seconds := 2.5) -> void:
	toast_text = message
	toast_time = seconds


func _save_game() -> void:
	var core_data: Array = []
	for core in cores:
		core_data.append({
			"x": core["pos"].x,
			"y": core["pos"].y,
			"jobs": core["jobs"],
			"spore_jobs": core.get("spore_jobs", []),
			"kind": String(core.get("kind", "normal")),
			"production_unit": String(core.get("production_unit", "forager")),
			"feeder_range_level": int(core.get("feeder_range_level", 0)),
			"biomass": float(core.get("biomass", CORE_MAX_BIOMASS)),
			"max_biomass": float(core.get("max_biomass", CORE_MAX_BIOMASS)),
			"alive": bool(core.get("alive", true)),
			"repair_reserve": float(core.get("repair_reserve", 0.0))
		})
	var segment_data: Array = []
	for segment in segments:
		segment_data.append({
			"ax": segment["a"].x, "ay": segment["a"].y,
			"bx": segment["b"].x, "by": segment["b"].y,
			"growth": segment["growth"], "core_id": segment["core_id"], "curve": segment["curve"],
			"orphaned": bool(segment.get("orphaned", false)), "viability": float(segment.get("viability", 1.0))
		})
	var resource_states: Array = []
	for resource in resources:
		if not bool(resource["alive"]) or float(resource["amount"]) < float(resource["initial_amount"]) - 0.0005:
			resource_states.append({"id": int(resource["id"]), "amount": float(resource["amount"])})
	var feeder_data: Array = []
	for feeder in feeders:
		feeder_data.append({
			"resource_id": int(feeder["resource_id"]),
			"core_id": int(feeder.get("core_id", 0)),
			"ax": feeder["a"].x, "ay": feeder["a"].y,
			"bx": feeder["b"].x, "by": feeder["b"].y,
			"growth": float(feeder["growth"]), "phase": float(feeder["phase"])
		})
	var bacteria_data: Array = []
	for bacterium in bacteria:
		bacteria_data.append({
			"x": bacterium["pos"].x,
			"y": bacterium["pos"].y,
			"stored": float(bacterium.get("stored", 0.0)),
			"cooldown": float(bacterium.get("cooldown", 0.0)),
			"biomass": float(bacterium.get("biomass", 1.0)),
			"resource_id": int(bacterium.get("resource_id", -1)),
			"seek_cooldown": float(bacterium.get("seek_cooldown", 0.0)),
			"contact_cooldown": float(bacterium.get("contact_cooldown", 0.0)),
			"in_contact": bool(bacterium.get("in_contact", false)),
			"event_id": int(bacterium.get("event_id", -1)),
			"strain": String(bacterium.get("strain", "normal")),
			"phase": float(bacterium.get("phase", 0.0))
		})
	var expedition_data: Array = []
	for unit in expedition_units:
		var unit_pos: Vector2 = unit["pos"]
		var target_pos: Vector2 = unit.get("target_pos", unit_pos)
		expedition_data.append({
			"id": int(unit.get("id", -1)),
			"unit_type": String(unit.get("unit_type", "forager")),
			"home_core_id": int(unit.get("home_core_id", -1)),
			"x": unit_pos.x, "y": unit_pos.y,
			"state": String(unit.get("state", "idle")),
			"target_kind": String(unit.get("target_kind", "")),
			"target_x": target_pos.x, "target_y": target_pos.y,
			"target_resource_id": int(unit.get("target_resource_id", -1)),
			"cargo_organic": float(unit.get("cargo_organic", 0.0)),
			"cargo_mineral": float(unit.get("cargo_mineral", 0.0)),
			"manual": bool(unit.get("manual", false)),
			"search_cooldown": float(unit.get("search_cooldown", 0.0)),
			"phase": float(unit.get("phase", 0.0))
		})
	var exploration_data: Array = explored_cells.keys()
	exploration_data.sort()
	var discovery_data: Array = discovered_hotspots.keys()
	discovery_data.sort()
	var ecology_data: Array = []
	for event in ecology_events:
		var event_pos: Vector2 = event.get("pos", Vector2.ZERO)
		ecology_data.append({
			"id": int(event.get("id", -1)),
			"type": String(event.get("type", "bloom")),
			"x": event_pos.x,
			"y": event_pos.y,
			"radius": float(event.get("radius", ECOLOGY_BLOOM_RADIUS)),
			"phase": String(event.get("phase", "warning")),
			"remaining": float(event.get("remaining", 0.0)),
			"anchor_core_id": int(event.get("anchor_core_id", 0)),
			"spawned": int(event.get("spawned", 0))
		})
	var data := {
		"version": 1,
		"world_generation": 5,
		"saved_at": Time.get_unix_time_from_system(),
		"organic": organic,
		"mineral": mineral,
		"dna": dna,
		"game_over": game_over,
		"diet_order": diet_order,
		"diet_levels": diet_levels,
		"bacteria_components": bacteria_components,
		"structure_levels": structure_levels,
		"survival_levels": survival_levels,
		"barracks_unit_unlocks": barracks_unit_unlocks,
		"diet_unit_unlocks": diet_unit_unlocks,
		"lifetime_organic_absorbed": lifetime_organic_absorbed,
		"lifetime_mineral_absorbed": lifetime_mineral_absorbed,
		"lifetime_dna_produced": lifetime_dna_produced,
		"lifetime_bacteria_births": lifetime_bacteria_births,
		"lifetime_bacteria_consumed": lifetime_bacteria_consumed,
		"lifetime_expedition_organic_returned": lifetime_expedition_organic_returned,
		"lifetime_expedition_mineral_returned": lifetime_expedition_mineral_returned,
		"lifetime_expedition_bacteria_killed": lifetime_expedition_bacteria_killed,
		"lifetime_ecology_events_seen": lifetime_ecology_events_seen,
		"lifetime_ecology_events_contained": lifetime_ecology_events_contained,
		"ecology_event_countdown": ecology_event_countdown,
		"next_ecology_event_id": next_ecology_event_id,
		"goals_claimed": goals_claimed,
		"scout_upgrade_levels": scout_upgrade_levels,
		"camera_x": camera_center.x,
		"camera_y": camera_center.y,
		"camera_zoom": camera_zoom,
		"cores": core_data,
		"segments": segment_data,
		"resource_states": resource_states,
		"feeders": feeder_data,
		"bacteria": bacteria_data,
		"expedition_units": expedition_data,
		"explored_cells": exploration_data,
		"discovered_hotspots": discovery_data,
		"ecology_events": ecology_data
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func _load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
		return false
	organic = float(parsed.get("organic", 220.0))
	mineral = float(parsed.get("mineral", 24.0))
	dna = int(parsed.get("dna", 0))
	diet_order.clear()
	for diet_id in parsed.get("diet_order", []):
		if DIET_IDS.has(String(diet_id)) and not diet_order.has(String(diet_id)):
			diet_order.append(String(diet_id))
	var saved_diet_levels: Dictionary = parsed.get("diet_levels", {})
	for diet_id in DIET_IDS:
		diet_levels[diet_id] = clampi(int(saved_diet_levels.get(diet_id, 0)), 0, 5)
	var saved_bacteria_components: Dictionary = parsed.get("bacteria_components", {})
	for component_id in BACTERIA_COMPONENT_IDS:
		bacteria_components[component_id] = clampi(int(saved_bacteria_components.get(component_id, 0)), 0, 3)
	var saved_structure_levels: Dictionary = parsed.get("structure_levels", {})
	for structure_id in STRUCTURE_IDS:
		structure_levels[structure_id] = clampi(int(saved_structure_levels.get(structure_id, 0)), 0, 4)
	var saved_survival_levels: Dictionary = parsed.get("survival_levels", {})
	for survival_id in SURVIVAL_IDS:
		survival_levels[survival_id] = clampi(int(saved_survival_levels.get(survival_id, 0)), 0, 4)
	var saved_barracks_unlocks: Dictionary = parsed.get("barracks_unit_unlocks", {})
	for unit_id in BARRACK_UNIT_IDS:
		barracks_unit_unlocks[unit_id] = true if unit_id == "forager" else bool(saved_barracks_unlocks.get(unit_id, false))
	var saved_scout_upgrades: Dictionary = parsed.get("scout_upgrade_levels", {})
	for scout_upgrade_id in SCOUT_UPGRADE_IDS:
		scout_upgrade_levels[scout_upgrade_id] = clampi(int(saved_scout_upgrades.get(scout_upgrade_id, 0)), 0, MAX_SCOUT_UPGRADE_LEVEL)
	var saved_diet_unit_unlocks: Dictionary = parsed.get("diet_unit_unlocks", {})
	diet_unit_unlocks["lytic"] = bool(saved_diet_unit_unlocks.get("lytic", false))
	lifetime_organic_absorbed = float(parsed.get("lifetime_organic_absorbed", 0.0))
	lifetime_mineral_absorbed = float(parsed.get("lifetime_mineral_absorbed", 0.0))
	lifetime_dna_produced = int(parsed.get("lifetime_dna_produced", 0))
	lifetime_bacteria_births = int(parsed.get("lifetime_bacteria_births", 0))
	lifetime_bacteria_consumed = int(parsed.get("lifetime_bacteria_consumed", 0))
	lifetime_expedition_organic_returned = float(parsed.get("lifetime_expedition_organic_returned", 0.0))
	lifetime_expedition_mineral_returned = float(parsed.get("lifetime_expedition_mineral_returned", 0.0))
	lifetime_expedition_bacteria_killed = int(parsed.get("lifetime_expedition_bacteria_killed", 0))
	lifetime_ecology_events_seen = maxi(0, int(parsed.get("lifetime_ecology_events_seen", 0)))
	lifetime_ecology_events_contained = maxi(0, int(parsed.get("lifetime_ecology_events_contained", 0)))
	ecology_event_countdown = clampf(float(parsed.get("ecology_event_countdown", ECOLOGY_FIRST_EVENT_MAX)), 0.0, ECOLOGY_EVENT_INTERVAL_MAX)
	next_ecology_event_id = maxi(1, int(parsed.get("next_ecology_event_id", 1)))
	goals_claimed = parsed.get("goals_claimed", {})
	camera_center = Vector2(float(parsed.get("camera_x", 0.0)), float(parsed.get("camera_y", 0.0)))
	camera_zoom = clampf(float(parsed.get("camera_zoom", 0.65)), 0.018, 2.4)
	explored_cells.clear()
	for explored_key in parsed.get("explored_cells", []):
		var key := int(explored_key)
		if key >= 0 and key < EXPLORATION_GRID_SIDE * EXPLORATION_GRID_SIDE:
			explored_cells[key] = true
	discovered_hotspots.clear()
	for hotspot_id in parsed.get("discovered_hotspots", []):
		discovered_hotspots[String(hotspot_id)] = true
	last_discovery_scan_cell_count = -1
	cores.clear()
	for item in parsed.get("cores", []):
		var core := _make_core(Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0))), String(item.get("kind", "normal")))
		core["jobs"] = item.get("jobs", [])
		core["spore_jobs"] = item.get("spore_jobs", [])
		core["production_unit"] = String(item.get("production_unit", "forager"))
		core["feeder_range_level"] = clampi(int(item.get("feeder_range_level", 0)), 0, MAX_FEEDER_RANGE_LEVEL)
		core["max_biomass"] = maxf(1.0, float(item.get("max_biomass", CORE_MAX_BIOMASS)))
		core["biomass"] = clampf(float(item.get("biomass", core["max_biomass"])), 0.0, float(core["max_biomass"]))
		core["alive"] = bool(item.get("alive", float(core["biomass"]) > 0.0005))
		core["repair_reserve"] = clampf(float(item.get("repair_reserve", 0.0)), 0.0, float(core["max_biomass"]))
		if not bool(core["alive"]):
			core["biomass"] = 0.0
			core["repair_reserve"] = 0.0
			(core["jobs"] as Array).clear()
			(core["spore_jobs"] as Array).clear()
		cores.append(core)
	if cores.is_empty():
		cores.append(_make_core(Vector2.ZERO))
	segments.clear()
	for item in parsed.get("segments", []):
		segments.append({
			"a": Vector2(float(item.get("ax", 0.0)), float(item.get("ay", 0.0))),
			"b": Vector2(float(item.get("bx", 0.0)), float(item.get("by", 0.0))),
			"growth": float(item.get("growth", 1.0)),
			"core_id": int(item.get("core_id", 0)),
			"curve": float(item.get("curve", 0.0)),
			"orphaned": bool(item.get("orphaned", false)),
			"viability": clampf(float(item.get("viability", 1.0)), 0.0, 1.0)
		})
	var world_generation := int(parsed.get("world_generation", 1))
	if world_generation < 5:
		# 大地图首次迁移时保留菌落进度，但重置镜头和资源状态，避免旧编号错配。
		camera_center = Vector2.ZERO
		camera_zoom = 0.65
	if world_generation >= 5:
		for state in parsed.get("resource_states", []):
			var resource := _resource_by_id(int(state.get("id", -1)))
			if resource.is_empty():
				continue
			resource["amount"] = clampf(float(state.get("amount", resource["initial_amount"])), 0.0, float(resource["initial_amount"]))
			resource["alive"] = float(resource["amount"]) > 0.0005
	feeders.clear()
	if world_generation >= 5:
		for item in parsed.get("feeders", []):
			var resource_id := int(item.get("resource_id", -1))
			var resource := _resource_by_id(resource_id)
			var feeder_core_id := int(item.get("core_id", 0))
			if resource.is_empty() or not bool(resource["alive"]) or not _is_core_alive(feeder_core_id):
				continue
			feeders.append({
				"resource_id": resource_id,
				"core_id": feeder_core_id,
				"a": Vector2(float(item.get("ax", 0.0)), float(item.get("ay", 0.0))),
				"b": Vector2(float(item.get("bx", 0.0)), float(item.get("by", 0.0))),
				"growth": clampf(float(item.get("growth", 0.0)), 0.0, 1.0),
				"phase": float(item.get("phase", 0.0))
			})
	if parsed.has("bacteria"):
		bacteria.clear()
		for item in parsed.get("bacteria", []):
			if bacteria.size() >= MAX_BACTERIA:
				break
			var bacterium := _make_bacterium(Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0))))
			bacterium["stored"] = maxf(0.0, float(item.get("stored", 0.0)))
			bacterium["cooldown"] = maxf(0.0, float(item.get("cooldown", 0.0)))
			bacterium["biomass"] = clampf(float(item.get("biomass", 1.0)), 0.0, 1.0)
			bacterium["resource_id"] = int(item.get("resource_id", -1))
			bacterium["seek_cooldown"] = maxf(0.0, float(item.get("seek_cooldown", 0.0)))
			bacterium["contact_cooldown"] = maxf(0.0, float(item.get("contact_cooldown", 0.0)))
			bacterium["in_contact"] = bool(item.get("in_contact", false))
			bacterium["event_id"] = int(item.get("event_id", -1))
			var saved_strain := String(item.get("strain", "normal"))
			bacterium["strain"] = saved_strain if saved_strain == "bloom" else "normal"
			bacterium["phase"] = float(item.get("phase", 0.0))
			bacteria.append(bacterium)
	ecology_events.clear()
	for item in parsed.get("ecology_events", []):
		if not ecology_events.is_empty():
			break
		var event_type := String(item.get("type", "bloom"))
		var event_phase := String(item.get("phase", "warning"))
		if event_type != "bloom" and event_type != "toxin":
			continue
		if event_phase != "warning" and event_phase != "active":
			continue
		var event_pos := Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0)))
		if not event_pos.is_finite() or event_pos.length() > WORLD_HALF:
			continue
		var default_radius := ECOLOGY_BLOOM_RADIUS if event_type == "bloom" else ECOLOGY_TOXIN_ZONE_RADIUS
		var event_id := maxi(1, int(item.get("id", next_ecology_event_id)))
		ecology_events.append({
			"id": event_id,
			"type": event_type,
			"pos": event_pos,
			"radius": clampf(float(item.get("radius", default_radius)), 40.0, 240.0),
			"phase": event_phase,
			"remaining": clampf(float(item.get("remaining", 0.0)), 0.0, ECOLOGY_BLOOM_ACTIVE_SECONDS),
			"anchor_core_id": clampi(int(item.get("anchor_core_id", 0)), 0, maxi(0, cores.size() - 1)),
			"spawned": clampi(int(item.get("spawned", 0)), 0, ECOLOGY_BLOOM_SPAWN_COUNT)
		})
		next_ecology_event_id = maxi(next_ecology_event_id, event_id + 1)
	expedition_units.clear()
	next_expedition_id = 1
	for item in parsed.get("expedition_units", []):
		if expedition_units.size() >= MAX_EXPEDITION_SPORES:
			break
		var unit_id := maxi(1, int(item.get("id", next_expedition_id)))
		var unit_pos := Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0)))
		expedition_units.append({
			"id": unit_id,
			"unit_type": String(item.get("unit_type", "forager")),
			"home_core_id": int(item.get("home_core_id", -1)),
			"pos": unit_pos,
			"state": String(item.get("state", "idle")),
			"target_kind": String(item.get("target_kind", "")),
			"target_pos": Vector2(float(item.get("target_x", unit_pos.x)), float(item.get("target_y", unit_pos.y))),
			"target_resource_id": int(item.get("target_resource_id", -1)),
			"cargo_organic": clampf(float(item.get("cargo_organic", 0.0)), 0.0, 9.0),
			"cargo_mineral": clampf(float(item.get("cargo_mineral", 0.0)), 0.0, 9.0),
			"manual": bool(item.get("manual", false)),
			"search_cooldown": maxf(0.0, float(item.get("search_cooldown", 0.0))),
			"command_until": 0.0,
			"reveal_cell": -1,
			"phase": float(item.get("phase", 0.0))
		})
		next_expedition_id = maxi(next_expedition_id, unit_id + 1)
	if not parsed.has("explored_cells") or explored_cells.is_empty():
		_update_exploration(false)
	_sync_hotspot_discoveries(false)
	last_discovery_scan_cell_count = explored_cells.size()
	game_over = bool(parsed.get("game_over", false)) or _living_core_count() <= 0
	if game_over:
		sim_speed = 0.0
	var now: float = Time.get_unix_time_from_system()
	var actual_elapsed := maxf(0.0, now - float(parsed.get("saved_at", now)))
	var settled_elapsed := minf(actual_elapsed, OFFLINE_CAP_SECONDS)
	_apply_offline_progress(settled_elapsed, actual_elapsed)
	# 立即写回新的 saved_at 和结算后状态，避免报告关闭前异常退出导致重复收益。
	if offline_report_open:
		_save_game()
	selected_core = -1
	selected_expedition_ids.clear()
	return true


func _total_core_biomass() -> float:
	var total := 0.0
	for core in cores:
		if bool(core.get("alive", true)):
			total += float(core.get("biomass", 0.0))
	return total


func _apply_offline_progress(seconds: float, actual_seconds: float = -1.0) -> void:
	offline_report_open = false
	offline_report.clear()
	if seconds < OFFLINE_MIN_SECONDS or game_over:
		return
	var observed_seconds := seconds if actual_seconds < 0.0 else maxf(seconds, actual_seconds)
	var before := {
		"organic": organic,
		"mineral": mineral,
		"dna": dna,
		"units": expedition_units.size(),
		"explored": explored_cells.size(),
		"explored_fraction": _explored_fraction(),
		"hotspots": _discovered_hotspot_count(),
		"absorbed_organic": lifetime_organic_absorbed,
		"absorbed_mineral": lifetime_mineral_absorbed,
		"returned_organic": lifetime_expedition_organic_returned,
		"returned_mineral": lifetime_expedition_mineral_returned,
		"bacteria_births": lifetime_bacteria_births,
		"bacteria_consumed": lifetime_bacteria_consumed,
		"biomass": _total_core_biomass(),
		"living_cores": _living_core_count()
	}
	var remaining := seconds
	var bacteria_remaining := minf(seconds, OFFLINE_BACTERIA_CAP_SECONDS)
	var hazard_remaining := minf(seconds, OFFLINE_HAZARD_CAP_SECONDS)
	var orphan_remaining := minf(seconds, OFFLINE_ORPHAN_CAP_SECONDS)
	offline_simulating = true
	while remaining > 0.0005:
		var step := minf(OFFLINE_STEP_SECONDS, remaining)
		sim_time += step
		_update_growth(step)
		_update_dna_jobs(step)
		_update_barracks_jobs(step)
		_discover_feeders()
		_update_feeders(step)
		_update_expedition_units(step, false)
		if bacteria_remaining > 0.0005:
			var bacteria_step := minf(step, bacteria_remaining)
			_update_bacteria(bacteria_step)
			bacteria_remaining -= bacteria_step
		if hazard_remaining > 0.0005:
			var hazard_step := minf(step, hazard_remaining)
			_update_core_hazards(hazard_step)
			hazard_remaining -= hazard_step
		if orphan_remaining > 0.0005:
			var orphan_step := minf(step, orphan_remaining)
			_update_orphaned_segments(orphan_step)
			orphan_remaining -= orphan_step
		remaining -= step
		if game_over:
			break
	offline_simulating = false
	_sync_hotspot_discoveries(false)
	last_discovery_scan_cell_count = explored_cells.size()
	offline_report = {
		"actual_seconds": observed_seconds,
		"settled_seconds": seconds - remaining,
		"capped": observed_seconds > OFFLINE_CAP_SECONDS + 0.5,
		"organic_delta": organic - float(before["organic"]),
		"mineral_delta": mineral - float(before["mineral"]),
		"dna_completed": dna - int(before["dna"]),
		"units_built": maxi(0, expedition_units.size() - int(before["units"])),
		"explored_cells": explored_cells.size() - int(before["explored"]),
		"explored_percent": (_explored_fraction() - float(before["explored_fraction"])) * 100.0,
		"hotspots": _discovered_hotspot_count() - int(before["hotspots"]),
		"absorbed_organic": lifetime_organic_absorbed - float(before["absorbed_organic"]),
		"absorbed_mineral": lifetime_mineral_absorbed - float(before["absorbed_mineral"]),
		"returned_organic": lifetime_expedition_organic_returned - float(before["returned_organic"]),
		"returned_mineral": lifetime_expedition_mineral_returned - float(before["returned_mineral"]),
		"bacteria_births": lifetime_bacteria_births - int(before["bacteria_births"]),
		"bacteria_consumed": lifetime_bacteria_consumed - int(before["bacteria_consumed"]),
		"biomass_delta": _total_core_biomass() - float(before["biomass"]),
		"living_cores_before": int(before["living_cores"]),
		"living_cores_after": _living_core_count()
	}
	offline_report_open = true
	toast_text = ""
	toast_time = 0.0
	discovery_banner_time = 0.0


func _format_duration(seconds: float) -> String:
	if seconds >= 3600.0:
		return "%0.1f 小时" % (seconds / 3600.0)
	if seconds < 60.0:
		return "%d 秒" % int(seconds)
	return "%d 分钟" % int(seconds / 60.0)
