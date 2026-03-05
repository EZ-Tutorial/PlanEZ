extends GdUnitTestSuite

## The scene runner used to simulate and interact with the scene during tests.
var runner: GdUnitSceneRunner
## The instanced network manager scene ready for testing.
var network_manager: Node

## Setup function called automatically by GDUnit4 before each test.
func before_test():
	runner = scene_runner("res://network/network_manager.tscn")
	network_manager = runner.scene()


## Tests if the scene and its main nodes are successfully loaded and initialized.
func test_scene_initialization():
	# Verify that the scene itself is loaded into memory
	assert_object(network_manager).is_not_null()
	
	# Verify that the UI elements and important nodes are properly assigned via @onready
	assert_object(network_manager.host_button).is_not_null()
	assert_object(network_manager.join_button).is_not_null()
	assert_object(network_manager.spawn_root).is_not_null()


## Tests the server creation logic when the host button is pressed.
func test_host_button_starts_server():
	# Verify initial state: the ENet peer should be disconnected
	assert_int(network_manager.network_peer.get_connection_status()).is_equal(MultiplayerPeer.CONNECTION_DISCONNECTED)
	# Simulate a click on the host button by emitting its signal
	network_manager.host_button.pressed.emit()
	# Verify the ENet peer is now listening/connected as a server
	assert_int(network_manager.network_peer.get_connection_status()).is_equal(MultiplayerPeer.CONNECTION_CONNECTED)
	assert_bool(network_manager.multiplayer.is_server()).is_true()
	# Verify the connection UI is hidden after successful hosting
	assert_bool(network_manager.get_node("CanvasLayer").visible).is_false()
	# Close the connection to clean up the peer state
	network_manager.network_peer.close()


## Tests the client connection logic when the join button is pressed.
func test_join_button_connects_client():
	# Verify initial state: the ENet peer should be disconnected
	assert_int(network_manager.network_peer.get_connection_status()).is_equal(MultiplayerPeer.CONNECTION_DISCONNECTED)
	# Simulate a click on the join button by emitting its signal
	network_manager.join_button.pressed.emit()
	# Verify the ENet peer is trying to connect or is connected, and is NOT the server
	assert_int(network_manager.network_peer.get_connection_status()).is_not_equal(MultiplayerPeer.CONNECTION_DISCONNECTED)
	assert_bool(network_manager.multiplayer.is_server()).is_false()
	# Verify the connection UI is hidden after attempting to join
	assert_bool(network_manager.get_node("CanvasLayer").visible).is_false()
	# Close the connection to clean up the peer state
	network_manager.network_peer.close()


## Tests if hosting a server successfully spawns the player's airplane with correct attributes.
func test_host_spawns_player_plane():
	# Verify that the spawn root is initially empty
	assert_int(network_manager.spawn_root.get_child_count()).is_equal(0)
	# Simulate a click on the host button to start the server
	network_manager.host_button.pressed.emit()
	# Verify that exactly one airplane has been spawned
	assert_int(network_manager.spawn_root.get_child_count()).is_equal(1)
	# Get the spawned airplane node
	var spawned_plane = network_manager.spawn_root.get_child(0)
	# Verify the plane's name is the server's peer ID ("1")
	assert_str(spawned_plane.name).is_equal("1")
	# Verify the network authority is properly assigned to the server (ID 1)
	assert_int(spawned_plane.get_multiplayer_authority()).is_equal(1)
	# Close the connection to clean up the peer state for future tests
	network_manager.network_peer.close()
