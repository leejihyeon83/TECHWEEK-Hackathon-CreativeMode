# scripts/entities/Customer.gd

extends Node2D

# 이 손님이 원하는 포션의 이름을 저장할 변수
var wanted_potion: String

# (만약 손님 씬 안에 말풍선용 Label 노드가 있다면)
# @onready var speech_bubble = $SpeechBubbleLabel 


##
# GameManager로부터 주문 정보를 받아와서 자신을 설정하는 함수
##
func setup(order_data: Dictionary):
	# 1. 전달받은 데이터에서 'potion' 값을 꺼내 나의 wanted_potion 변수에 저장합니다.
	self.wanted_potion = order_data["potion"]

	# 2. 전달받은 데이터에서 'dialogue' 값을 꺼내 콘솔에 출력합니다. (테스트용)
	# print("손님 설정 완료! 내가 원하는 포션: ", wanted_potion)
	# print("손님 대사: ", order_data["dialogue"])
	
	# 3. (만약 말풍선 Label이 있다면) 말풍선의 텍스트를 설정합니다.
	# speech_bubble.text = order_data["dialogue"]
