extends Node
class_name PotionManager   # 전역 클래스 등록

# ===== 시그널 =====
signal potion_craft_success(potion_name: String)
signal potion_craft_fail
signal ingredient_added(ingredient_name: String, tray_size: int)
signal ingredient_removed(ingredient_name: String, tray_size: int, index: int)
signal tray_cleared

# ===== 상태 =====
var current_ingredients: Array[String] = []
const TRAY_CAPACITY := 2

# JSON 예: { "Red_Blue": "Purple", "Red_Yellow": "Orange", ... }
var recipes: Dictionary[String, String] = {}
const RECIPES_PATH := "res://resources/recipes.json"

# --------------------------
# 초기화
# --------------------------
func _ready() -> void:
    load_recipes()
    clear_tray()

# --------------------------
# 레시피 로드
# --------------------------
func load_recipes() -> void:
    if not FileAccess.file_exists(RECIPES_PATH):
        push_warning("recipes.json not found at %s" % RECIPES_PATH)
        return

    var file := FileAccess.open(RECIPES_PATH, FileAccess.READ)
    if file == null:
        push_warning("Failed to open recipes.json")
        return

    # 핵심: Variant로 '명시'하고, 이후 is/cast로 분기
    var data: Variant = JSON.parse_string(file.get_as_text())

    if data is Dictionary:
        recipes.clear()
        var raw: Dictionary = data as Dictionary
        for k in raw.keys():
            var key_str: String = String(k)
            var val_str: String = String(raw[k])
            recipes[key_str] = val_str
    else:
        push_warning("Invalid format in recipes.json (must be a JSON object mapping String->String)")


# --------------------------
# 재료 추가
# --------------------------
func add_ingredient(ingredient_name: String) -> void:
    if current_ingredients.size() >= TRAY_CAPACITY:
        return
    current_ingredients.append(ingredient_name)
    emit_signal("ingredient_added", ingredient_name, current_ingredients.size())

# --------------------------
# 재료 제거
# --------------------------
func remove_ingredient_at(index: int) -> bool:
    if index < 0 or index >= current_ingredients.size():
        return false
    var removed := current_ingredients[index]
    current_ingredients.remove_at(index)
    emit_signal("ingredient_removed", removed, current_ingredients.size(), index)
    return true

# --------------------------
# 트레이 비우기
# --------------------------
func clear_tray() -> void:
    current_ingredients.clear()
    emit_signal("tray_cleared")

# --------------------------
# 현재 트레이 상태 읽기
# --------------------------
func get_current_ingredients() -> Array[String]:
    return current_ingredients.duplicate()

# --------------------------
# 포션 제작 및 판정
# --------------------------
func craft_potion() -> void:
    if current_ingredients.is_empty():
        emit_signal("potion_craft_fail")
        clear_tray()
        return

    # 예: ["Red", "Blue"] -> "Red_Blue"
    # (레시피 키가 순서 무관이라면 여기를 정렬로 바꾸세요: current_ingredients.duplicate().sort())
    var key: String = "_".join(current_ingredients)

    if recipes.has(key):
        var potion_name: String = recipes[key]
        emit_signal("potion_craft_success", potion_name)
    else:
        emit_signal("potion_craft_fail")

    clear_tray()
