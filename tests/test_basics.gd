extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

func test_sum() -> void:
	var sum_result: int = 1 + 1
	assert_int(sum_result).is_equal(2)
