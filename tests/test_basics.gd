extends GdUnitTestSuite
@warning_ignore('unused_parameter')
@warning_ignore('return_value_discarded')

func test_sum() -> void:
	var sum_result: int = 1 + 1
	assert_int(sum_result).is_equal(2)

func test_max() -> void:
	var a: int = 1
	var b: int = 2
	var max_value: int = max(a, b)
	assert_int(max_value).is_equal(b)
