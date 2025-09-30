extends Node
class_name PotionManager

# ===== 시그널 정의 =====
signal potion_craft_success(potion_name: String)   # 포션 제작 성공 시 포션 이름 전달
signal potion_craft_fail                           # 포션 제작 실패 시 알림
signal ingredient_added(ingredient_name: String, tray_size: int) # 재료 추가 시 알림
signal tray_cleared                                # 트레이 초기화 시 알림

# ===== 상태 변수 =====
var current_ingredients: Array[String] = []  # 현재 트레이에 담긴 재료들
const TRAY_CAPACITY := 2                     # 트레이 최대 용량

var recipes: Dictionary = {}                 # JSON에서 불러온 포션 레시피 데이터

const RECIPES_PATH := "res://resources/recipes.json"  # 레시피 JSON 경로


# --------------------------
# 초기화
# --------------------------
func _ready() -> void:
    # 게임 시작 시 레시피 불러오고 트레이 초기화
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
    if file:
        var data: Variant = JSON.parse_string(file.get_as_text())  # ⬅️ 타입 명시
        if typeof(data) == TYPE_DICTIONARY:
            recipes = data as Dictionary                            # ⬅️ 캐스팅(선택)
        else:
            push_warning("Invalid format in recipes.json")
    else:
        push_warning("Failed to open recipes.json")


# --------------------------
# 재료 추가
# --------------------------
func add_ingredient(ingredient_name: String) -> void:
    # 트레이 용량이 다 찼으면 무시
    if current_ingredients.size() >= TRAY_CAPACITY:
        return
    
    # 재료 추가
    current_ingredients.append(ingredient_name)
    # 재료 추가됨을 알림 (UI 업데이트 등)
    emit_signal("ingredient_added", ingredient_name, current_ingredients.size())


# --------------------------
# 트레이 비우기
# --------------------------
func clear_tray() -> void:
    # 현재 재료 전부 제거
    current_ingredients.clear()
    # 트레이가 비워졌음을 알림
    emit_signal("tray_cleared")


# --------------------------
# 포션 제작 및 판정
# --------------------------
# --------------------------
# 포션 제작 및 판정
# --------------------------
func craft_potion() -> void:
    # 트레이가 비어 있으면 제작 실패
    if current_ingredients.is_empty():
        emit_signal("potion_craft_fail")
        clear_tray()
        return

    # 현재 재료들을 "_"로 이어붙여 키 생성
    # 예: ["Red", "Blue"] -> "Red_Blue"
    var key: String = current_ingredients.join("_") 

    # 레시피에 해당 키가 존재하면 제작 성공
    if recipes.has(key):
        # 4.0에서는 String() 캐스팅보다 타입 추론이 권장되나, 명시적으로 유지 가능
        var potion_name: String = recipes[key] 
        emit_signal("potion_craft_success", potion_name)
    else:
        # 해당 조합이 없으면 제작 실패
        emit_signal("potion_craft_fail")

    # 제작 후 트레이는 항상 비움
    clear_tray()