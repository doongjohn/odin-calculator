package main

import "core:math"
import "core:fmt"
import "eval"

@(private = "file")
Test_Data :: struct {
	input: string,
	result: f64,
}

@(private = "file")
test :: proc(tests: []Test_Data) {
	passed, failed: int
	for data in tests {
		input := data.input
		expected := data.result

		print_input_prompt()
		fmt.println(input)

		result, ok := eval.evaluate(input)
		if ok {
			fmt.printf("  = {:.6f}\n", result)
			if result == expected {
				passed += 1
				fmt.println("🟢 passed\n")
			} else {
				failed += 1
				fmt.printf("🔴 failed\nexpected: {:.6f})\n", expected)
			}
		} else {
			failed += 1
			fmt.println("❌ failed to evaluate\n")
		}
	}

	fmt.println("test result")
	fmt.println("-----------")
	if (failed == 0) {
		fmt.println("all tests passed")
	} else {
		fmt.printf("🔴 {} tests out of {} tests failed\n", failed, len(tests))
	}
}

test_all :: proc() {
	tests := [?]Test_Data {
		{
			"10",
			10,
		},
		{
			"-12",
			-12,
		},
		{
			"10+2",
			10+2,
		},
		{
			"+10-+12",
			10-12,
		},
		{
			"-10++10--10",
			-10 + 10 + 10,
		},
		{
			"10+2*3",
			10+2*3,
		},
		{
			"10+2*3^2",
			10 + 2 * math.pow_f64(3, 2),
		},
		{
			"10 * 3 + pi * 2",
			10 * 3 + math.PI * 2,
		},
		{
			"(200)",
			200,
		},
		{
			"(200+10*2)",
			200+10*2,
		},
		{
			"(2+3) * 2 + 1",
			(2+3) * 2 + 1,
		},
		{
			"2 * (2 + 10)",
			2 * (2 + 10),
		},
		{
			"(200+10*2)+(3+2^2)",
			(200+10*2)+(3+math.pow_f64(2, 2)),
		},
		{
			"(2 * (3 + 1 * 2)) + 1",
			(2 * (3 + 1 * 2)) + 1,
		},
		{
			"1 + (2 + 2) * 10 ^ 2",
			1 + (2 + 2) * math.pow_f64(10, 2),
		},
		{
			"2 + -(2 / ((2)))",
			2 + -(2 / 2),
		},
		{
			"2 + +(2 / 2)--(13*12+2)",
			2 + (2 / 2)- -(13*12+2),
		},
	}
	test(tests[:])
}
