# res://scripts/GameScene.gd
extends Control

# =========================================
# =============== Export ===================
# =========================================
@export_group("Timer / Score")
@export var ROUND_TIME := 90.0

@export_group("Shelf Buttons")
@export var shelf_button_size := Vector2(64, 64)
@export var shelf_button_gap := 8.0
# 버튼에 쓸 텍스처(없으면 텍스트 버튼으로 표시)
@export var tex_red: Texture2D
@export var tex_blue: Texture2D
@export var tex_yellow: Texture2D

@export_group("UI / Icons (Optional)")
@export var tex_pause: Texture2D      # 없어도 동작
@export var tex_recipe_icon: Texture2D

@export_group("Customers")
@export var customer_textures: Array[Texture2D] = []  # 랜덤 손님 외형

# =========================================
# ============== Node Cache ===============
# =========================================
@onready var Background: TextureRect      = $Background
@onready var HUD_Layer: CanvasLayer       = $HUD_Layer
@onready var TopBar: HBoxContainer        = $HUD_Layer/TopBar
@onready var PauseButton: TextureButton   = $HUD_Layer/TopBar/PauseButton

@onready var InteractionArea: Control     = $InteractionArea
@onready var CustomerSprite: Sprite2D     = $InteractionArea/CustomerSprite
@onready var BubbleArea: TextureRect      = $InteractionArea/BubbleArea
@onready var RecipeButton: TextureButton  = $InteractionArea/RecipeButton

@onready var CraftingUI: Control          = $CraftingUI
@onready var TrayBackground: TextureRect  = $CraftingUI/TrayBackground
@onready var Slot1_Pos: Marker2D          = $CraftingUI/TrayBackground/Slot1_Pos
@onready var Slot2_Pos: Marker2D          = $CraftingUI/TrayBackground/Slot2_Pos
@onready var CurrentPotionA: TextureRect  = $CraftingUI/CurrentPotionA
@onready var CurrentPotionB: TextureRect  = $CraftingUI/CurrentPotionB
@onready var CraftButton: TextureButton   = $CraftingUI/CraftButton

@onready var _timer_panel := TopBar.get_node_or_null("VBoxContainer/Timer_Panel") as TextureRect
@onready var _coin_panel  := TopBar.get_node_or_null("VBoxContainer/Coin_Panel") as TextureRect

# 동적 생성 노드
var _timer_label: Label
var _coin_label: Label
var _order_label: Label                     # 말풍선 안의 주문 텍스트
var _shelf_container: Node2D                # 선반 버튼 부모

# =========================================
# ============== Game State ===============
# =========================================
var time_left := 0.0
var coins := 0
var current_order := ""                     # 손님 주문(결과 포션 이름)

# PotionManager 인스턴스 (팀원 코드 사용)
const PotionManagerClass = preload("res://scripts/system/PotionManager.gd")
var PM: PotionManagerClass

# =========================================
# ================= Ready =================
# =========================================
func _ready() -> void:
	# PotionManager 생성/부착
	PM = PotionManagerClass.new()
	add_child(PM)

	# PM 시그널 연결
	PM.potion_craft_success.connect(_on_potion_craft_success)
	PM.potion_craft_fail.connect(_on_potion_craft_fail)
	PM.ingredient_added.connect(_on_ingredient_added)
	PM.ingredient_removed.connect(_on_ingredient_removed)
	PM.tray_cleared.connect(_on_tray_cleared)

	# HUD 라벨 준비
	_setup_hud_labels()

	# 버튼 핸들러
	if tex_pause: PauseButton.texture_normal = tex_pause
	PauseButton.pressed.connect(_on_pause_pressed)

	if tex_recipe_icon: RecipeButton.texture_normal = tex_recipe_icon
	RecipeButton.pressed.connect(_on_recipe_pressed)

	CraftButton.pressed.connect(_on_craft_pressed)

	# 선반 버튼 생성(빨/파/노)
	_build_shelf_buttons()

	# 초기 타이머/코인
	time_left = ROUND_TIME
	_update_timer_label()
	_update_coin_label()

	# 첫 손님 소환
	_spawn_customer_and_order()

	# 말풍선 안 주문 라벨 준비
	_prepare_order_label()

func _process(delta: float) -> void:
	if get_tree().paused: return

	time_left = max(0.0, time_left - delta)
	_update_timer_label()

	# 10초 경고: 시각 효과(깜빡임)
	if int(time_left) == 10:
		_blink_label(_timer_label)

	if time_left <= 0.0:
		_end_game()

# =========================================
# ================ HUD ====================
# =========================================
func _setup_hud_labels() -> void:
	# Timer
	if _timer_panel:
		_timer_label = _timer_panel.get_node_or_null("TimerLabel") as Label
		if _timer_label == null:
			_timer_label = Label.new()
			_timer_label.name = "TimerLabel"
			_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_timer_label.size_flags_horizontal = Control.SIZE_EXPAND
			_timer_label.size_flags_vertical = Control.SIZE_EXPAND
			_timer_label.text = "90"
			_timer_panel.add_child(_timer_label)

	# Coins
	if _coin_panel:
		_coin_label = _coin_panel.get_node_or_null("CoinLabel") as Label
		if _coin_label == null:
			_coin_label = Label.new()
			_coin_label.name = "CoinLabel"
			_coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_coin_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_coin_label.size_flags_horizontal = Control.SIZE_EXPAND
			_coin_label.size_flags_vertical = Control.SIZE_EXPAND
			_coin_label.text = "Coins: 0"
			_coin_panel.add_child(_coin_label)

func _update_timer_label() -> void:
	if _timer_label:
		_timer_label.text = str(int(ceil(time_left)))

func _update_coin_label() -> void:
	if _coin_label:
		_coin_label.text = "Coins: %d" % coins

func _blink_label(label: Label) -> void:
	if label == null: return
	var tw := create_tween()
	tw.tween_property(label, "modulate:a", 0.2, 0.15).from(1.0)
	tw.tween_property(label, "modulate:a", 1.0, 0.15)

# =========================================
# ============== Shelf Buttons ============
# =========================================
func _build_shelf_buttons() -> void:
	# 컨테이너 생성
	_shelf_container = Node2D.new()
	_shelf_container.name = "ShelfButtons"
	InteractionArea.add_child(_shelf_container)

	var colors := [
		{"name":"Red", "tex":tex_red},
		{"name":"Blue","tex":tex_blue},
		{"name":"Yellow","tex":tex_yellow}
	]

	var x := 32.0
	var y := get_viewport_rect().size.y - (shelf_button_size.y + 32.0)  # 화면 하단 근처
	for item in colors:
		var btn := TextureButton.new()
		btn.custom_minimum_size = shelf_button_size
		btn.position = Vector2(x, y)
		if item.tex:
			btn.texture_normal = item.tex
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		else:
			# 텍스처 없으면 텍스트 버튼 대체
			var b := Button.new()
			b.text = item.name
			b.position = Vector2(x, y)
			b.custom_minimum_size = shelf_button_size
			b.pressed.connect(_on_ingredient_button_pressed.bind(item.name))
			InteractionArea.add_child(b)
			x += shelf_button_size.x + shelf_button_gap
			continue

		btn.pressed.connect(_on_ingredient_button_pressed.bind(item.name))
		_shelf_container.add_child(btn)
		x += shelf_button_size.x + shelf_button_gap

func _on_ingredient_button_pressed(ing_name: String) -> void:
	# 팀원 코드: add_ingredient(ingredient_name: String)
	PM.add_ingredient(ing_name)

# =========================================
# ============ Tray / Selection ===========
# =========================================
func _on_ingredient_added(ing_name: String, tray_size: int) -> void:
	# CurrentPotionA / B 표시 갱신
	if tray_size == 1:
		_set_current_potion(CurrentPotionA, ing_name, true)
	elif tray_size == 2:
		_set_current_potion(CurrentPotionB, ing_name, true)

func _on_ingredient_removed(ing_name: String, tray_size: int, index: int) -> void:
	# index: 제거된 슬롯 인덱스
	if index == 0:
		_set_current_potion(CurrentPotionA, "", false)
		# B가 앞으로 당겨졌다고 가정하여 재표시(간단화)
		_copy_tex(CurrentPotionB, CurrentPotionA)
		_set_current_potion(CurrentPotionB, "", false)
	elif index == 1:
		_set_current_potion(CurrentPotionB, "", false)

func _on_tray_cleared() -> void:
	_set_current_potion(CurrentPotionA, "", false)
	_set_current_potion(CurrentPotionB, "", false)

func _set_current_potion(node: TextureRect, ing_name: String, visible_state: bool) -> void:
	node.visible = visible_state
	if not visible_state:
		return
	# 버튼 텍스처를 그대로 재사용(없으면 유지)
	match ing_name:
		"Red":
			if tex_red: node.texture = tex_red
		"Blue":
			if tex_blue: node.texture = tex_blue
		"Yellow":
			if tex_yellow: node.texture = tex_yellow
		_:
			# 혹시 레시피에 특수케이스가 있으면 그대로 둠
			pass

# 두 TextureRect 간 텍스처 복사
func _copy_tex(from: TextureRect, to: TextureRect) -> void:
	to.texture = from.texture
	to.visible = from.visible

# =========================================
# ============== Crafting =================
# =========================================
func _on_craft_pressed() -> void:
	PM.craft_potion()   # 판정은 PM이 하고, 결과는 시그널로 수신

# 팀원 시그널: 성공(포션 이름 문자열) / 실패
func _on_potion_craft_success(potion_name: String) -> void:
	_show_crafted_popup(potion_name)

func _on_potion_craft_fail() -> void:
	_show_crafted_popup("Fail")  # 실패 팝업도 동일 UI로 처리

# 결과 팝업(간단)
func _show_crafted_popup(result_name: String) -> void:
	var dim := ColorRect.new()
	dim.name = "CraftResultDim"
	dim.color = Color(0,0,0,0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.size = get_viewport_rect().size
	$TopLayer.add_child(dim)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND
	center.size_flags_vertical = Control.SIZE_EXPAND
	dim.add_child(center)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(240, 220)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND
	vb.size_flags_vertical = Control.SIZE_EXPAND
	panel.add_child(vb)

	var icon := TextureRect.new()
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(160, 140)
	icon.texture = _guess_texture_for_result(result_name)
	vb.add_child(icon)

	var label := Label.new()
	label.text = result_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(label)

	dim.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_evaluate_result_and_close(result_name, dim)
	)

func _guess_texture_for_result(name: String) -> Texture2D:
	# 간단 매핑: 결과 이름이 기본 재료명과 같을 수도 있음
	match name:
		"Red":    return tex_red
		"Blue":   return tex_blue
		"Yellow": return tex_yellow
		_:        return null  # 혼합 결과 이미지는 필요 시 확장

func _evaluate_result_and_close(result_name: String, pop: Control) -> void:
	if result_name == current_order:
		coins += 100
		_update_coin_label()
		_spawn_customer_and_order()
	else:
		_spawn_customer_and_order()
	pop.queue_free()

# =========================================
# ============ Customer / Order ===========
# =========================================
func _spawn_customer_and_order() -> void:
	# 손님 스킨
	if customer_textures.size() > 0:
		CustomerSprite.texture = customer_textures[randi() % customer_textures.size()]

	# 주문은 PM의 레시피 값에서 랜덤 추출 + 단일 재료(선택 사항)
	var orders := _collect_possible_orders()
	if orders.is_empty():
		current_order = "Red"  # 안전장치
	else:
		current_order = orders[randi() % orders.size()]

	_show_order_text(current_order)

func _collect_possible_orders() -> Array[String]:
	var set: Dictionary[String, bool] = {}

    # 딕셔너리 타입을 로컬에서 고정
	var rec: Dictionary[String, String] = PM.recipes

	for k: String in rec.keys():
		var v: String = rec[k]        # ← 이제 타입 확정
		set[v] = true

    # 단일 재료도 주문에 포함
	set["Red"] = true
	set["Blue"] = true
	set["Yellow"] = true

	var arr: Array[String] = []
	for n: String in set.keys():
		arr.append(n)
	return arr



func _prepare_order_label() -> void:
	_order_label = BubbleArea.get_node_or_null("OrderLabel") as Label
	if _order_label == null:
		_order_label = Label.new()
		_order_label.name = "OrderLabel"
		_order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_order_label.size_flags_horizontal = Control.SIZE_EXPAND
		_order_label.size_flags_vertical = Control.SIZE_EXPAND
		BubbleArea.add_child(_order_label)

func _show_order_text(txt: String) -> void:
	BubbleArea.visible = true
	if _order_label == null:
		_prepare_order_label()
	_order_label.text = txt

# =========================================
# ========== Pause / Recipe Popup =========
# =========================================
func _on_pause_pressed() -> void:
	get_tree().paused = true
	if has_node("/root/SceneRouter"):
		get_node("/root/SceneRouter").show_pause_popup()
	else:
		print("[Pause] open (router not found)")

func _on_recipe_pressed() -> void:
	if has_node("/root/SceneRouter"):
		var list := _recipe_list_for_popup()
		get_node("/root/SceneRouter").show_recipe_book(list)
	else:
		print("[Recipe] open (router not found)")

func _recipe_list_for_popup() -> Array[String]:
	var lines: Array[String] = []
	for k in PM.recipes.keys():
		lines.append("%s → %s" % [k, String(PM.recipes[k])])
	return lines

# =========================================
# ================ End Game ===============
# =========================================
func _end_game() -> void:
	get_tree().paused = true
	var result := {
		"coins": coins,
		"customers": 0,
		"elapsed": ROUND_TIME
	}
	if has_node("/root/SceneRouter"):
		get_node("/root/SceneRouter").show_end_screen(result)
	else:
		print("[End] ", result)
