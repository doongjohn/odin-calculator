package main

// TODO:
// - [x] ascii input
// - [x] multi-digit number
// - [x] +- prefixed number
// - [x] floating point number
// - [x] operator precedence
// - [x] grouping with parentheses
// - [x] predefined constants
// - [ ] unicode input
// - [ ] custom constants
// - [ ] custom math functions
// - [ ] custom infix operator

// References:
// https://en.wikipedia.org/wiki/Shunting-yard_algorithm
// https://en.wikipedia.org/wiki/Operator-precedence_parser

import "core:io"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:math"
import "eval"

print_input_prompt :: proc() {
	fmt.print(">>> ")
}

print_error_prompt :: proc() {
	fmt.print("ERR:")
}

print_calc_result :: proc(result: f64) {
    fmt.printf("  = {:.6f}\n", result)
}

// TODO: replace this with readline or linenoise...
stdin_readline :: proc() -> strings.Builder {
    stdin_stream := os.stream_from_handle(os.stdin)
    stdin_reader := io.to_byte_reader(stdin_stream)
    input_builder := strings.make_builder_none()

    ch, err := u8(0), io.Error.None
    for {
        ch, err = io.read_byte(stdin_reader)
        if ch == '\n' || err != .None { break }
        strings.write_byte(&input_builder, ch)
    }

    return input_builder
}

main :: proc() {
    for {
		print_input_prompt()
		input_str_builder := stdin_readline()
        defer strings.destroy_builder(&input_str_builder)

        input := strings.trim_space(strings.to_string(input_str_builder))
		switch input {
		case "exit", "quit":
			return
		case "test":
			test_all()
		case:
			result, ok := eval.evaluate(input)
			if ok {
				print_calc_result(result)
			} else {
				// TODO: print error
			}
			fmt.println()
		}
	}
}

Test_Data :: struct {
	input: string,
	result: f64,
}

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
				fmt.printf("🔴 failed\nexpected: {:.6f})\n\n", expected)
			}
		} else {
			failed += 1
			fmt.println("❗failed to evaluate\n")
		}
	}
	fmt.printf("🟢 passed: {}\n🔴 falied: {}\n", passed, failed)
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
			"2 + -(2 / 2)",
			2 + -(2 / 2),
		},
	}
	test(tests[:])
}
