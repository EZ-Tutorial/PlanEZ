extends GdUnitTestSuite

## The scene runner used to simulate and interact with the scene during tests.
var runner: GdUnitSceneRunner
## The instanced network manager scene ready for testing.
var network_manager: Node
## Reference to the CanvasLayer node containing the connection UI.
var connection_layer: CanvasLayer
## Reference to the CanvasLayer node containing the failed connection UI.
var failed_connection_layer: CanvasLayer
## Reference to the CanvasLayer node containing the server disconnection UI.
var server_disconnected_layer: CanvasLayer

## Setup function called automatically by GDUnit4 before each test.
func before_test():
	runner = scene_runner("res://network/network_manager.tscn")
	network_manager = runner.scene()
	
	connection_layer = network_manager.get_node("ConnectionLayer")
	failed_connection_layer = network_manager.get_node("ConnectionFailedLayer")
	server_disconnected_layer = network_manager.get_node("ServerDisconnectedLayer")


## Tests if the scene and its main nodes are successfully loaded and initialized.
func test_scene_initialization():
	# Verify that the scene itself is loaded into memory
	assert_object(network_manager).is_not_null()
	
	# Verify that the UI elements and important nodes are properly assigned via @onready
	assert_object(network_manager.host_button).is_not_null()
	assert_object(network_manager.join_button).is_not_null()
	assert_object(network_manager.spawn_root).is_not_null()
	
	# Verify fetched node are also present
	assert_object(connection_layer).is_not_null()
	assert_object(failed_connection_layer).is_not_null()
	assert_object(server_disconnected_layer).is_not_null()

## Tests the server creation logic when the host button is pressed.
func test_host_button_starts_server():
	# Verify initial state: the ENet peer should be disconnected
	assert_int(network_manager.network_peer.get_connection_status()).is_equal(MultiplayerPeer.CONNECTION_DISCONNECTED)
	
	# Verify the ENet peer is now listening/connected as a server
	network_manager.host_button.pressed.emit()
	assert_int(network_manager.network_peer.get_connection_status()).is_equal(MultiplayerPeer.CONNECTION_CONNECTED)
	assert_bool(network_manager.multiplayer.is_server()).is_true()
	
	# Verify the connection UI is hidden after successful hosting
	assert_bool(connection_layer.visible).is_false()
	
	# Close the connection to clean up the peer state
	network_manager.network_peer.close()


## Tests the client connection logic when the join button is pressed.
func test_join_button_connects_client():
	# Verify initial state: the ENet peer should be disconnected
	assert_int(network_manager.network_peer.get_connection_status()).is_equal(MultiplayerPeer.CONNECTION_DISCONNECTED)
	
	# Verify the ENet peer is trying to connect or is connected, and is NOT the server
	network_manager.join_button.pressed.emit()
	assert_int(network_manager.network_peer.get_connection_status()).is_not_equal(MultiplayerPeer.CONNECTION_DISCONNECTED)
	assert_bool(network_manager.multiplayer.is_server()).is_false()
	
	# Verify the connection UI is hidden after attempting to join
	assert_bool(connection_layer.visible).is_false()
	
	# Close the connection to clean up the peer state
	network_manager.network_peer.close()


## Tests if hosting a server successfully spawns the player's airplane with correct attributes.
func test_host_spawns_player_plane():
	# Verify that the spawn root is initially empty
	assert_int(network_manager.spawn_root.get_child_count()).is_equal(0)
	
	# Verify that exactly one airplane has been spawned
	network_manager.host_button.pressed.emit()
	assert_int(network_manager.spawn_root.get_child_count()).is_equal(1)
	
	# Verify the plane's name is the server's peer ID ("1")
	var spawned_plane = network_manager.spawn_root.get_child(0)
	assert_str(spawned_plane.name).is_equal("1")
	
	# Verify the network authority is properly assigned to the server (ID 1)
	assert_int(spawned_plane.get_multiplayer_authority()).is_equal(1)
	
	# Close the connection to clean up the peer state for future tests
	network_manager.network_peer.close()


## Tests if a player disconnecting correctly removes their airplane from the spawn root.
func test_player_disconnect_removes_plane() -> void:
	# Host a server (spawns player 1)
	network_manager.host_button.pressed.emit()
	assert_int(network_manager.spawn_root.get_child_count()).is_equal(1)
	
	# Simulate a second player connecting
	network_manager._spawn_player(2)
	assert_int(network_manager.spawn_root.get_child_count()).is_equal(2)
	
	# Simulate the second player disconnecting and verify the plane was removed
	network_manager.multiplayer.peer_disconnected.emit(2)
	await get_tree().process_frame
	assert_int(network_manager.spawn_root.get_child_count()).is_equal(1)
	assert_object(network_manager.spawn_root.get_node_or_null("2")).is_null()
	
	# Close the connection
	network_manager.network_peer.close()


## Tests if the connection failure UI is displayed when the client fails to connect to a server.
func test_connection_failed_shows_ui() -> void:
	# Simulate a client failing to join a server
	network_manager.join_button.pressed.emit()
	network_manager.multiplayer.connection_failed.emit()
	
	# Verify the UI reacting to the failure is shown
	assert_bool(failed_connection_layer.visible).is_true()
	
	# Close the connection to clean up the peer state
	network_manager.network_peer.close()


## Tests if the connection failure UI is displayed when the server disconnects the client.
func test_server_disconnection_shows_ui() -> void:
	# Simulate the server closing the connection
	network_manager.join_button.pressed.emit()
	network_manager.multiplayer.server_disconnected.emit()
	
	# Verify the UI reacting to the disconnection is shown
	assert_bool(server_disconnected_layer.visible).is_true()
	
	# Close the connection to clean up the peer state
	network_manager.network_peer.close()
