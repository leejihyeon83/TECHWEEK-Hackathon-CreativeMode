extends Node

# ==============================================================================
# 시그널: 게임의 중요한 순간을 다른 노드들에게 알리는 신호탄
# ==============================================================================
# 게임이 처음 시작되었을 때 발생하는 신호
signal game_started
# 게임이 끝났을 때 발생하는 신호
signal game_over
# 점수가 업데이트될 때마다 현재 점수를 담아서 보내는 신호
signal score_updated(new_score)
# 시간이 업데이트될 때마다 남은 시간을 담아서 보내는 신호
signal time_updated(current_time)


# ==============================================================================
# 변수: 게임의 현재 상태를 기억하는 저장 공간
# ==============================================================================
# 게임이 현재 플레이 중인지 여부 (true/false)
var is_playing: bool = false
# 현재 점수
var score: int = 0
# 남은 시간 (초 단위). 3분 = 180초
var time_left: float = 180.0


# 손님 설계도(Customer.tscn)를 미리 불러와서 변수에 저장해둡니다.
const CustomerScene = preload("res://scenes/Customer.tscn")

var order_database: Array = [] # JSON 파일에서 읽어온 주문 데이터 전체를 담을 배열
var current_customer = null    # 현재 화면에 있는 손님 노드를 저장할 변수



# 게임이 처음 시작될 때 딱 한 번 호출되는 함수
func _ready():
	# 게임을 '플레이 중' 상태로 바꿉니다.
	is_playing = true
	# "게임 시작!" 신호를 다른 모든 노드에게 보냅니다.
	game_started.emit()
	# 손님을 부르기 전에, 주문 데이터베이스부터 불러옵니다.
	load_dialogues()
	# 게임이 시작되면 첫 손님을 소환합니다.
	spawn_customer()


# 매 프레임마다 계속해서 호출되는 함수
func _process(delta):
	# 만약 게임이 '플레이 중'이 아니라면, 아래 코드를 실행하지 않고 건너뜁니다.
	if not is_playing:
		return

	# 시간이 남아있다면
	if time_left > 0:
		# 남은 시간을 매 프레임 지난 시간(delta)만큼 줄입니다.
		time_left -= delta
		# 현재 남은 시간을 계속해서 다른 노드에게 알립니다 (UI 업데이트용)
		time_updated.emit(time_left)
	# 만약 시간이 다 되었다면
	else:
		# 게임을 '종료' 상태로 바꿉니다.
		is_playing = false
		# "게임 오버!" 신호를 다른 모든 노드에게 보냅니다.
		game_over.emit()
		# 우리가 눈으로 확인할 수 있도록 콘솔에 메시지를 출력합니다.
		print("게임 오버!")


# ==============================================================================
# 점수 관리: 점수를 획득하고 다른 곳에 알리는 함수
# ==============================================================================
# 'amount' 만큼 점수를 추가하는 함수
func add_score(amount: int):
	# 현재 점수(score)에 amount를 더합니다.
	score += amount
	# "점수 변경!" 신호를 새로운 점수와 함께 보냅니다.
	score_updated.emit(score)
	# 우리가 눈으로 확인할 수 있도록 콘솔에 메시지를 출력합니다.
	print("점수 획득! 현재 점수: ", score)


# ==============================================================================
# 데이터 로드: 게임에 필요한 외부 데이터를 불러오는 함수
# ==============================================================================
# dialogues.json 파일을 읽어 order_database 변수를 채우는 함수
func load_dialogues():
	var path = "res://resources/dialogues.json"

	if not FileAccess.file_exists(path):
		push_warning("dialogues.json 파일을 찾을 수 없습니다: " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json_data = JSON.parse_string(content)

	if json_data:
		order_database = json_data
	else:
		push_warning("dialogues.json 파일의 형식이 잘못되었습니다.")


# ==============================================================================
# 손님 관리: 손님을 생성하고 관리하는 함수들
# ==============================================================================
# 새로운 손님을 생성하고 화면에 배치하는 함수
# 새로운 손님을 생성하고 화면에 배치하는 함수
func spawn_customer():
	# 1. 기존 손님이 있다면 화면에서 먼저 삭제합니다.
	if is_instance_valid(current_customer):
		current_customer.queue_free()

	# 2. 데이터베이스에서 무작위 주문({potion:"...", dialogue:"..."})을 하나 뽑습니다.
	var random_order = order_database.pick_random()

	# 3. 손님 객체를 생성하고, 'current_customer' 변수에 저장합니다.
	current_customer = CustomerScene.instantiate()

	# 4. (중요!) 손님에게 주문 정보를 통째로 넘겨줍니다.
	#    이제 Customer.gd 스크립트에서 이 정보를 받아 처리해야 합니다.
	current_customer.setup(random_order)
	print("손님이 등장했습니다! 주문 내용: ", random_order["dialogue"])

	# 5. 손님 위치를 설정하고 화면에 추가합니다.
	current_customer.position = Vector2(150, 300)
	add_child(current_customer)


# 포션을 전달받았을 때 호출될 함수 (Phase 2에서 완성될 예정)
# 포션을 전달받았을 때 호출될 함수
func check_potion_delivery(delivered_potion: String):
	# 현재 손님이 없으면 아무것도 하지 않습니다.
	if not is_instance_valid(current_customer):
		return

	# 전달된 포션과 손님이 원한 포션이 일치하는지 확인합니다.
	if delivered_potion == current_customer.wanted_potion:
		# 정답이면 100점을 추가합니다.
		add_score(100)

	# 정답이든 아니든, 다음 손님을 즉시 소환합니다.
	spawn_customer()

	
func _on_potion_manager_potion_craft_success(potion_name: String):
	# PotionManager가 보내준 포션 이름을 그대로 check_potion_delivery 함수에 전달합니다.
	check_potion_delivery(potion_name)
