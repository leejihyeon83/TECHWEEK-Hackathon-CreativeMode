extends Node


# ===== 시그널 정의 =====
signal potion_craft_success(potion_name: String)   # 포션 제작 성공 시 포션 이름을 전달
signal potion_craft_fail                           # 포션 제작 실패 시 알림
signal ingredient_added(ingredient_name: String, tray_size: int) # 재료 추가 시 (재료 이름, 현재 트레이 크기) 전달
signal ingredient_removed(ingredient_name: String, tray_size: int, index: int) # ← [추가] 트레이에서 재료 제거 시 알림
signal tray_cleared                                # 트레이 초기화 시 알림

# ===== 상태 변수 =====
var current_ingredients: Array[String] = []  # 현재 트레이에 담긴 재료들
const TRAY_CAPACITY := 2                     # 트레이 최대 용량 (재료 2개까지만 담을 수 있음)

var recipes: Dictionary = {}                 # JSON에서 불러온 포션 레시피 데이터 저장
const RECIPES_PATH := "res://resources/recipes.json"  # 레시피 JSON 경로

# --------------------------
# 초기화
# --------------------------
func _ready() -> void:
	# 노드가 준비되면 실행됨
	# 1) JSON에서 레시피 불러오기
	# 2) 트레이 초기화
	load_recipes()
	clear_tray()

# --------------------------
# 레시피 로드
# --------------------------
func load_recipes() -> void:
	# 레시피 JSON 파일이 없으면 경고 출력
	if not FileAccess.file_exists(RECIPES_PATH):
		push_warning("recipes.json not found at %s" % RECIPES_PATH)
		return

	# 파일 열기 (읽기 전용 모드)
	var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
	if file:
		# 파일 내용을 문자열로 읽고 JSON으로 파싱
		var data = JSON.parse_string(file.get_as_text())

		# 파싱 결과가 Dictionary 형태라면 recipes에 저장
		if typeof(data) == TYPE_DICTIONARY:
			recipes = data as Dictionary
		else:
			# JSON 구조가 잘못된 경우
			push_warning("Invalid format in recipes.json")
	else:
		# 파일 열기 실패
		push_warning("Failed to open recipes.json")

# --------------------------
# 재료 추가
# --------------------------
func add_ingredient(ingredient_name: String) -> void:
	# 트레이 용량이 다 찼으면 재료를 더 넣을 수 없음
	if current_ingredients.size() >= TRAY_CAPACITY:
		return
	
	# 재료 추가
	current_ingredients.append(ingredient_name)
	
	# 재료가 추가되었음을 시그널로 알림 (UI 갱신 등에 사용)
	emit_signal("ingredient_added", ingredient_name, current_ingredients.size())

# --------------------------
# 재료 제거 (트레이 슬롯 클릭)
# --------------------------
func remove_ingredient_at(index: int) -> bool:
	# 인덱스 유효성 검사
	if index < 0 or index >= current_ingredients.size():
		return false
	# 제거 수행
	var removed := current_ingredients[index]
	current_ingredients.remove_at(index)
	# 제거되었음을 시그널로 알림 (UI 갱신 등에 사용)
	emit_signal("ingredient_removed", removed, current_ingredients.size(), index)
	return true

# --------------------------
# 트레이 비우기
# --------------------------
func clear_tray() -> void:
	# 현재 담긴 재료를 모두 제거
	current_ingredients.clear()
	# 트레이가 비워졌음을 알림
	emit_signal("tray_cleared")

# --------------------------
# 현재 트레이 상태 읽기 (UI용 헬퍼)
# --------------------------
func get_current_ingredients() -> Array[String]:
	return current_ingredients.duplicate()

# --------------------------
# 포션 제작 및 판정
# --------------------------
func craft_potion() -> void:
	# 트레이가 비어있으면 제작 실패
	if current_ingredients.is_empty():
		emit_signal("potion_craft_fail")
		clear_tray()
		return

	# 현재 재료 배열을 "_"로 이어붙여서 키를 만듦
	# 예: ["Red", "Blue"] -> "Red_Blue"
	var key: String = "_".join(current_ingredients)

	# 레시피에 해당 키가 존재하면 성공
	if recipes.has(key):
		var potion_name := String(recipes[key])
		emit_signal("potion_craft_success", potion_name)
	else:
		# 레시피에 없는 조합이면 실패
		emit_signal("potion_craft_fail")

	# 제작 후에는 항상 트레이를 비움
	clear_tray()
