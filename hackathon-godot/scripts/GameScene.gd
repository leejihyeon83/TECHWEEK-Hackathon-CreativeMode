# res://scripts/GameScene.gd - PotionManager 최종 버전 반영

extends Control

# Autoload 싱글톤 참조 (class_name 사용)
# PotionManager는 Autoload로 설정되어야 합니다.
const SceneRouter = preload("res://scripts/system/SceneRouter.gd") 
const PotionManager = preload("res://scripts/system/PotionManager.gd") 

# 재료 ID 대신 문자열 이름을 사용하도록 변경 (PotionManager의 규약 반영)
const INGREDIENT_NAMES = {
    "Red": "res://assets/Art/04_Items/potion_red.png",
    "Blue": "res://assets/Art/04_Items/potion_blue.png",
    "Yellow": "res://assets/Art/04_Items/potion_yellow.png",
}

# 노드 경로 단축
@onready var score_label = $HUD_Layer/TopBar/Coin_Panel/ScoreLabel 
@onready var time_bar = $HUD_Layer/TopBar/TimeBar 
@onready var pause_button = $HUD_Layer/TopBar/PauseButton
@onready var recipe_button = $InteractionArea/RecipeButton 
@onready var shelf_area = $InteractionArea/ShelfArea 

@onready var craft_button = $CraftingUI/CraftButton
@onready var potion_a = $CraftingUI/CurrentPotionA 
@onready var potion_b = $CraftingUI/CurrentPotionB 
@onready var slot1_pos = $CraftingUI/TrayBackground/Slot1_Pos 
@onready var slot2_pos = $CraftingUI/TrayBackground/Slot2_Pos 

var current_time = 180.0 # 3분 = 180초
var current_coins = 0

# =======================================================
# 초기화 및 준비
# =======================================================

func _ready():
    print("[LOGIC] 게임 씬 초기화 시작")

    # 1. HUD 초기화
    _update_score_display(current_coins)
    time_bar.max_value = 180.0
    
    # 2. 버튼 신호 연결 (에디터에서 수동 연결 필요!)
    pause_button.pressed.connect(_on_PauseButton_pressed)
    recipe_button.pressed.connect(_on_RecipeButton_pressed)
    craft_button.pressed.connect(_on_craft_button_pressed)
    
    # 3. PotionManager 시그널 연결 (가장 중요!)
    PotionManager.ingredient_added.connect(_on_ingredient_added)
    PotionManager.tray_cleared.connect(_on_tray_cleared)
    PotionManager.potion_craft_success.connect(_on_potion_craft_success)
    PotionManager.potion_craft_fail.connect(_on_potion_craft_fail)
    # PotionManager.ingredient_removed.connect(_on_ingredient_removed) # 제거 기능 구현 시 연결
    
    # 4. 재료 선반 초기화
    _initialize_shelf_buttons()
    
    # 5. 첫 손님 등장 (로직만 표시)
    _spawn_new_customer()


# =======================================================
# 게임 루프 (타이머)
# =======================================================

func _process(delta):
    if get_tree().paused:
        return

    # 시간 감소 로직
    if current_time > 0:
        current_time -= delta
        time_bar.value = current_time
        _check_time_critical()
    else:
        current_time = 0
        time_bar.value = 0
        _game_over()

# 10초 남았을 때 체크
func _check_time_critical():
    if current_time <= 10.0 and time_bar.modulate != Color.RED:
        time_bar.modulate = Color.RED # 시각적 경고


# =======================================================
# UI 업데이트 및 관리
# =======================================================

func _update_score_display(score):
    score_label.text = "Coins: " + str(score)

func _clear_tray_ui():
    potion_a.visible = false
    potion_b.visible = false
    potion_a.texture = null
    potion_b.texture = null

func _spawn_new_customer():
    print("[LOGIC] 손님 등장 로직 실행")
    # 손님 캐릭터 표시 로직 구현 필요

# =======================================================
# 입력 및 상호작용 로직
# =======================================================

# 재료 버튼 동적 생성 (INGREDIENT_NAMES 기반)
func _initialize_shelf_buttons():
    var x_start = 50 # 선반 영역 시작 x 좌표 (수동 조정 필요)
    var y_pos = 50 
    
    for name in INGREDIENT_NAMES:
        var button = TextureButton.new()
        var texture = load(INGREDIENT_NAMES[name])
        
        button.texture_normal = texture 
        button.texture_pressed = texture
        button.position = Vector2(x_start, y_pos)
        button.set_custom_minimum_size(Vector2(64, 64))
        
        # 버튼 클릭 시 _on_ingredient_pressed 함수 호출 연결
        button.pressed.connect(_on_ingredient_pressed.bind(name, texture))
        
        shelf_area.add_child(button)
        y_pos += 100


func _on_ingredient_pressed(ingredient_name: String, texture: Texture2D):
    print("[LOGIC] 재료 선택: ", ingredient_name)
    
    # PotionManager의 재료 추가 함수 호출
    PotionManager.add_ingredient(ingredient_name)


func _on_craft_button_pressed():
    print("[LOGIC] 제작 버튼 클릭")
    
    # PotionManager에 포션 제작 요청
    PotionManager.craft_potion()
    
    # 제작 요청 후 제작 중에는 버튼 비활성화
    craft_button.disabled = true


func _on_PauseButton_pressed():
    print("[LOGIC] 일시정지 버튼 클릭")
    SceneRouter.show_pause_popup()
    get_tree().paused = true


func _on_RecipeButton_pressed():
    print("[LOGIC] 레시피 버튼 클릭")
    
    # PotionManager의 레시피 데이터를 가져와서 팝업에 전달 (recipes는 Dictionary)
    var recipe_data = PotionManager.recipes # PotionManager의 공개 변수 사용
    SceneRouter.show_recipe_book(recipe_data) 
    get_tree().paused = true
    

# =======================================================
# PotionManager 시그널 수신 (UI 업데이트)
# =======================================================

# 재료가 트레이에 추가되었을 때 호출됨
func _on_ingredient_added(ingredient_name: String, tray_size: int):
    var texture = load(INGREDIENT_NAMES[ingredient_name])
    
    # 트레이에 포션 시각화
    if tray_size == 1:
        potion_a.texture = texture
        potion_a.visible = true
        # 포션 위치 조정
        potion_a.global_position = slot1_pos.global_position - potion_a.size * 0.5
    elif tray_size == 2:
        potion_b.texture = texture
        potion_b.visible = true
        # 포션 위치 조정
        potion_b.global_position = slot2_pos.global_position - potion_b.size * 0.5


# 트레이가 비워졌을 때 호출됨 (제작 후, 또는 초기화 시)
func _on_tray_cleared():
    _clear_tray_ui()
    craft_button.disabled = false # 제작 완료 또는 실패 시 버튼 활성화


# 포션 제작 성공 시 호출됨
func _on_potion_craft_success(potion_name: String):
    print("[LOGIC] 포션 제작 성공: ", potion_name)
    # B 프론트엔드에게 성공한 포션으로 팝업을 띄우도록 요청
    SceneRouter.show_result_potion_popup(potion_name) 
    # 제작 후에는 트레이가 자동으로 비워지므로, _on_tray_cleared가 호출됨


# 포션 제작 실패 시 호출됨
func _on_potion_craft_fail():
    print("[LOGIC] 포션 제작 실패 (알 수 없는 조합)")
    # B 프론트엔드에게 실패 팝업을 띄우도록 요청
    SceneRouter.show_result_potion_popup("실패")
    # 제작 후에는 트레이가 자동으로 비워지므로, _on_tray_cleared가 호출됨
    

# =======================================================
# 게임 종료
# =======================================================

func _game_over():
    print("[LOGIC] 게임 오버")
    
    var result = {
        "coins": current_coins,
        "customers": 0,
        "elapsed": 180.0
    }
    
    SceneRouter.show_end_screen(result)