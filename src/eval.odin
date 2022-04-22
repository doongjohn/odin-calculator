package calc

import "core:math"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"

parse_const :: proc(str: string) -> (end: int, num: f64, ok: bool) {
	// parse predefined constants
	// return:
	//     end => index where parsing is ended
	//     num => value of the constant
	//     ok  => is an input successfully parsed as constant

	ok = true
	length := len(str)
	is_prefixed := strings.index_byte("+-", str[0]) >= 0
	sign: f64 = 1
	if is_prefixed && str[0] == '-' do sign = -1

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
	return
}

parse_paren :: proc(str: string) -> (end: int, ok: bool) {
	// parse parentheses
	// return:
	//     i  => index where parsing is ended
	//     ok => is parentheses has a matching pair
	// TODO: include sign

	length := len(str)
	open_count: uint = 1

	if length < 2 || str[0] != '(' {
		ok = false; return
	}

	for end < length - 1 {
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

Op_Data :: struct {
	num: f64,
	op: u8,
}

// TODO: make eval function
evaluate :: proc(input: string) -> (result: f64, ok: bool) {
	// - try parse constant
	// - try parse number
	// - try parse paren
	// - try parse operator
	// - update oplist
	//   - do calculation
	//     - clear oplist

	oplist := [3]Op_Data {
		Op_Data{ num = 0, op = 0 }, // operator precedence 0
		Op_Data{ num = 0, op = 0 }, // operator precedence 1
		Op_Data{ num = 0, op = 0 }, // operator precedence 2
	}
	context.user_ptr = ^oplist

	clear_oplist :: proc() {
		context.user_ptr^ = {
			Op_Data{ num = 0, op = 0 },
			Op_Data{ num = 0, op = 0 },
			Op_Data{ num = 0, op = 0 },
		}
	}

	length = len(input)
	cur_index = 0
	cur_char: u8 = 0
	cur_opdata = Op_Data{ num = 0, op = 0 }
	proc_ok = false

	for cur_index < length - 1 {
		// try parse constant
		cur_index, num, proc_ok = parse_const(input[cur_index:])
		if (ok) {
			cur_opdata.num = num
			continue
		}

		// try parse number literal
		cur_index, num, proc_ok = parse_number(input[cur_index:])
		if (ok) {
			cur_opdata.num = num
			continue
		}

		// try parse parentheses
		cur_index, proc_ok = parse_paren(input[cur_index:])
		if (ok) {
			// try evaluate expression
			num, proc_ok = evaluate(input[cur_index:])
			if (!proc_ok) {
				// TODO: error
			}
			continue
		}

		// TODO: try parse operator
		// op: u8 = 0
		// cur_index, op, proc_ok = parse_op(input[cur_index:])
		// if (proc_ok) {
		// 	cur_opdata.op = op
		// 	continue
		// }
	}
}
