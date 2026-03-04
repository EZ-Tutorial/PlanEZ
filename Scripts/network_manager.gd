extends Node

@onready var host_button: Button = $CanvasLayer/VBoxContainer/HostButton
@onready var join_button: Button = $CanvasLayer/VBoxContainer/JoinButton

const SERVER_PORT = 7070
const SERVER_IP = "127.0.0.1"
const MAX_PLAYERS = 10

var network_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func _ready():
	# Connect UI buttons to their respective functions
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	# Listen to connection events
	multiplayer.peer_connected.connect(_on_player_connected)

func _on_host_pressed():
	var error = network_peer.create_server(SERVER_PORT, MAX_PLAYERS)
	if error == OK:
		multiplayer.multiplayer_peer = network_peer
		print("Server successfully started on port: ", SERVER_PORT)
		
		# The server also hides the UI so we can see the game later
		$CanvasLayer.hide()

func _on_join_pressed():
	var error = network_peer.create_client(SERVER_IP, SERVER_PORT)
	if error == OK:
		multiplayer.multiplayer_peer = network_peer
		print("Attempting to join server at: ", SERVER_IP)
		
		# The client hides the UI
		$CanvasLayer.hide()

func _on_player_connected(peer_id: int):
	# This will print on the server when a client joins, 
	# and on the client when they successfully connect to the server
	print("Player connected! ID: ", peer_id)
