package eval

import "core:math"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"

parse_space :: proc(str: string) -> (end: int, ok: bool) {
	// parse white space
	// return:
	//     end => index where parsing is ended
	//     ok  => is an input successfully parsed as white space

	ok = true
	length := len(str)

	if (length == 0) {
		ok = false; return
	}

	for end < length - 1 {
		end += 1
		if (str[end] != " ") {
			end -= 1; return
		}
	}

	ok = false; return
}

parse_const :: proc(str: string) -> (end: int, num: f64, ok: bool) {
	// parse predefined constants
	// return:
	//     end => index where parsing is ended
	//     num => value of the constant
	//     ok  => is an input successfully parsed as constant

	ok = true
	length := len(str)
	is_prefixed := strings.index_byte("+-", str[0]) >= 0
	sign := 1
	if is_prefixed && str[0] == "-" do sign = -1

	if length == 0 || strings.index_byte(".0123456789*/^", str[0]) >= 0 {
		ok = false; return
	}

	for end < length - 1 {
		end += 1
		if strings.index_byte("+-*/^ ", str[end]) >= 0 {
			end -= 1
			break
		}
	}
	end += 1

	start := 0
	if is_prefixed do start = 1
	switch str[start:end] {
	case "pi" : num = math.PI
	case "tau": num = math.TAU
	case "e"  : num = math.E
	}
	num *= sign

	if num != 0 do return
	ok = false; return
}

parse_number :: proc(str: string) -> (end: int, num: f64, ok: bool) {
	// parse string as f64 number
	// NOTE: `+`, `-` prefix is part of the number
	// return:
	//     end => index where parsing is ended
	//     num => parsed number
	//     ok  => is an input successfully parsed as f64

	ok = true
	length := len(str)
	is_prefixed := strings.index_byte("+-", str[0]) >= 0

	if is_prefixed && (length == 1 || strings.index_byte(".0123456789", str[1]) < 0) {
		ok = false; return
	}

	for end < length - 1 {
		end += 1
		// HACK: can be optimized
		num, ok = strconv.parse_f64(str[:end])
		if !ok {
			if end == 1 {
				// cannot parse as float
				ok = false; return
			} else {
				// parse ended
				end -= 1; return
			}
		}
	}

	unreachable("wut")
	return
}

// FIXME: test this (i think this is broken)
parse_paren :: proc(str: string) -> (end: int, ok: bool) {
	// parse parentheses
	// return:
	//     i  => index where parsing is ended
	//     ok => is parentheses match

	length := len(str)
	open_count: uint = 1

	if str_len < 2 || str[0] != '(' {
		ok = false; return
	}

	for end < str_len - 1 {
		end += 1
		switch str[end] {
		case '(':
			open_count += 1
		case ')':
			open_count -= 1
			if open_count < 0 {
				ok = false; return
			}
		}
	}

	end += 1
	ok = open_count == 0
	return
}

evaluate :: proc(input: string) {
	// TODO: make eval function
}
