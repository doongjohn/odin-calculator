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
	fmt.print("ERR:")
}

print_calc_result :: proc(result: f64) {
    fmt.printf("  = {:.6f}\n", result)
}

// TODO: replace this with readline or linenoise...
readline_from_stdin :: proc() -> (str_builder: strings.Builder, error: io.Error) {
	stdin_stream := os.stream_from_handle(os.stdin)
	stdin_reader := io.to_byte_reader(stdin_stream)
	str_builder = strings.make_builder_none()
	char: u8
	delim: u8 = '\n'
	for {
		char = io.read_byte(stdin_reader) or_return
		if char == delim do break
		strings.write_byte(&str_builder, char)
	}
	return
}

main :: proc() {
    for {
		print_input_prompt()
		input_str_builder, readline_error := readline_from_stdin()
		defer strings.destroy_builder(&input_str_builder)
		if readline_error != .None {
			print_error_prompt()
			fmt.printf("`io.read_byte` {}\n", readline_error)
			strings.destroy_builder(&input_str_builder)
			os.exit(1) // defer does not work after os.exit() because the program exits here
		}

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
				// TODO: print proper error msg
				print_error_prompt()
				fmt.println("unknown command / invalid expression")
			}
			fmt.println()
		}
	}
}
