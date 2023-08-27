package main

// TODO:
// - [x] ascii input
// - [x] multi-digit number
// - [x] +- prefixed number
// - [x] floating point number
// - [x] operator precedence
// - [x] grouping with parentheses
// - [x] predefined constants
// - [ ] predefined functions
// - [ ] unicode input
// - [ ] custom constants
// - [ ] custom functions
// - [ ] custom infix operator

import "core:math"
import "core:strings"
import "core:fmt"
import "core:io"
import "core:os"
import "eval"

print_input_prompt :: proc() {
	fmt.print(">>> ")
}

print_error_prompt :: proc() {
	fmt.print("ERR: ")
}

print_calc_result :: proc(result: f64) {
    fmt.printf("  = {:.6f}\n", result)
}

readline :: proc() -> (str_builder: strings.Builder, error: io.Error) {
	stdin_reader := io.to_reader(os.stream_from_handle(os.stdin))
	str_builder = strings.builder_make()
	delimiter: rune = '\n'
	for {
		r, _ := io.read_rune(stdin_reader) or_return
		if r == delimiter do break
		strings.write_rune(&str_builder, r)
	}
	return str_builder, io.Error.None
}

main :: proc() {
	// for {
	// 	print_input_prompt()
		input_str_builder, stdin_err := readline()
		defer strings.builder_destroy(&input_str_builder)

		if stdin_err != .None {
			print_error_prompt()
			fmt.printf("`io.read_byte` {}\n", stdin_err)
			strings.builder_destroy(&input_str_builder)

			os.exit(1)
			// NOTE: defer does not work after `os.exit()`
		}

		input := strings.trim_space(strings.to_string(input_str_builder))
		fmt.printf("{}\n", input)

	// 	switch input {
	// 	case "exit", "quit":
	// 		return

	// 	case "test":
	// 		test_all()

	// 	case:
	// 		result, ok := eval.evaluate(input)
	// 		if ok {
	// 			print_calc_result(result)
	// 		} else {
	// 			// TODO: print proper error msg
	// 			print_error_prompt()
	// 			fmt.println("unknown command / invalid expression")
	// 		}
	// 		fmt.println()
	// 	}
	// }
}
