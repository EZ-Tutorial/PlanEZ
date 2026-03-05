extends Node

const SERVER_PORT = 7070
const SERVER_IP = "127.0.0.1"

@export_category("Network")
## Max amount of player in the server.
@export var max_player: int = 10

@export_category("Planes")
## The scene representing the player's airplane.
@export var plane_scene: PackedScene

## Network peer instance handling the multiplayer connection over UDP.
var network_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

## Layer for connection
@onready var connection_layer: CanvasLayer = $ConnectionLayer
## The button used to start hosting a game server.
@onready var host_button: Button = $ConnectionLayer/VBoxContainer/HostButton
## The button used to join an existing game server.
@onready var join_button: Button = $ConnectionLayer/VBoxContainer/JoinButton
## The 3D node where all airplanes will be spawned.
@onready var spawn_root: Node3D = $SpawnRoot

## Layer for connection failed
@onready var connection_failed_layer: CanvasLayer = $ConnectionFailedLayer

## Layer for server disconnection
@onready var server_disconnected_layer: CanvasLayer = $ServerDisconnectedLayer


func _ready():
	# Connect UI buttons to their respective functions
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Creates a server, then hides the connection UI upon success.
func _on_host_pressed():
	var server = network_peer.create_server(SERVER_PORT, max_player)
	if server == OK:
		multiplayer.multiplayer_peer = network_peer
		connection_layer.hide()
		
		multiplayer.peer_connected.connect(_spawn_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		_spawn_player(1)

## Attempts to connect to the server as a client and hides the connection UI upon success.
func _on_join_pressed():
	var server = network_peer.create_client(SERVER_IP, SERVER_PORT)
	if server == OK:
		multiplayer.multiplayer_peer = network_peer
		connection_layer.hide()


## Triggered when the client fails to connect to the server.
func _on_connection_failed():
	connection_failed_layer.show()
	# Optional: Show an error message

## Triggered when the server disconnects the client.
func _on_server_disconnected():
	server_disconnected_layer.show()


## Instantiates the player scene, sets the network authority, and adds it to the spawn root.
func _spawn_player(peer_id: int):
	var new_plane = plane_scene.instantiate()
	# Naming the node with the peer ID to track it over the network
	new_plane.name = str(peer_id)
	# Assign network authority so only the specific client can control this airplane later
	new_plane.set_multiplayer_authority(peer_id)
	# Adding the child to the spawn_root triggers the MultiplayerSpawner automatically
	spawn_root.add_child(new_plane)

## Triggered when a client disconnects. Removes the player's airplane from the scene.
func _remove_player(peer_id: int):
	var plane_to_remove = spawn_root.get_node_or_null(str(peer_id))
	if plane_to_remove:
		plane_to_remove.queue_free()
