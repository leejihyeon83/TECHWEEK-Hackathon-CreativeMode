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
var time_left: int = 180


# 손님 설계도(Customer.tscn)를 미리 불러와서 변수에 저장해둡니다.
const CustomerScene = preload("res://scenes/Customer.tscn")

# 손님이 주문할 가능성이 있는 포션 이름 목록
var potion_list = ["힘의 포션", "지혜의 포션", "민첩의 포션"]


# 게임이 처음 시작될 때 딱 한 번 호출되는 함수
func _ready():
	# 게임을 '플레이 중' 상태로 바꿉니다.
	is_playing = true
	# "게임 시작!" 신호를 다른 모든 노드에게 보냅니다.
	game_started.emit()
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
# 손님 관리: 손님을 생성하고 관리하는 함수들
# ==============================================================================
# 새로운 손님을 생성하고 화면에 배치하는 함수
func spawn_customer():
	# 1. 불러온 설계도로부터 실제 손님 객체(인스턴스)를 찍어냅니다.
	var customer = CustomerScene.instantiate()
	
	# 2. 포션 목록에서 무작위로 하나를 골라 손님의 주문으로 설정합니다.
	var random_potion = potion_list.pick_random()
	customer.wanted_potion = random_potion
	print("손님이 등장했습니다! 원하는 포션: ", customer.wanted_potion)
	
	# 3. 손님을 화면의 특정 위치에 배치합니다. (임시로 x:150, y:300 위치)
	customer.position = Vector2(150, 300)
	
	# 4. 생성된 손님을 Main 씬의 자식으로 추가하여 화면에 보이게 합니다.
	add_child(customer)


# 포션을 전달받았을 때 호출될 함수 (Phase 2에서 완성될 예정)
func check_potion_delivery(delivered_potion: String):
	print("포션 전달됨:", delivered_potion, " / 손님이 원한 포션:", "아직 확인 로직 없음")
