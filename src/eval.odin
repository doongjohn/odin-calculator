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

parse_op :: proc(str: string) -> (end: int, op: proc(a, b: f64) -> f64, op_pcd: u8, ok: bool) {
	// parse operator
	// return:
	//     i      => index where parsing is ended
	// 	   op     => operation function
	// 	   op_pcd => operation precedence
	//     ok     => is parentheses has a matching pair

	ok = true
	length := len(str)

	ops := [?]string{
		"+",
		"-",
		"*",
		"/",
		"^",
	}
	op_pcds := [?]u8 {
		0,
		0,
		1,
		1,
		2,
	}
	op_procs := [?]proc(a, b: f64) -> f64 {
		proc(a, b: f64) -> f64 { return a + b },
		proc(a, b: f64) -> f64 { return a - b },
		proc(a, b: f64) -> f64 { return a * b },
		proc(a, b: f64) -> f64 { return a / b },
		proc(a, b: f64) -> f64 { return math.pow(a, b) },
	}

	for opstr, i in ops {
		if opstr == str[:len(opstr)] {
			end = len(opstr) + 1
			op = op_procs[i]
			op_pcd = op_pcds[i]
			return
		}
	}

	ok = false; return
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
	op: proc(a, b: f64) -> f64,
	op_pcd: u8,
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

	TokenType :: enum {
		None,
		Number,
		Operator,
	}

	oplist := [?]Op_Data {
		Op_Data{ num = 0, op = nil, op_pcd = 0 }, // operator precedence 0
		Op_Data{ num = 0, op = nil, op_pcd = 0 }, // operator precedence 1
		Op_Data{ num = 0, op = nil, op_pcd = 0 }, // operator precedence 2
	}
	context.user_ptr = &oplist

	clear_oplist :: proc() {
		(^[3]Op_Data)(context.user_ptr)^ = {
			Op_Data{ num = 0, op = nil, op_pcd = 0 },
			Op_Data{ num = 0, op = nil, op_pcd = 0 },
			Op_Data{ num = 0, op = nil, op_pcd = 0 },
		}
	}

	length := len(input)
	cur_i: int = 0
	cur_c: u8 = 0
	num: f64 = 0
	proc_ok := false
	cur_opdata := Op_Data{ num = 0, op = nil }
	prev_token: TokenType = .None

	for cur_i < length - 1 {
		ok = false

		cur_c = input[cur_i]

		// ignore white space
		if cur_c == ' ' do continue

		// try parse constant
		cur_i, num, proc_ok = parse_const(input[cur_i:])
		if ok {
			cur_opdata.num = num
			prev_token = .Number
			continue
		}

		// try parse number literal
		cur_i, num, proc_ok = parse_number(input[cur_i:])
		if ok {
			cur_opdata.num = num
			prev_token = .Number
			continue
		}

		// try parse parentheses
		cur_i, proc_ok = parse_paren(input[cur_i:])
		if ok {
			// try evaluate expression
			num, proc_ok = evaluate(input[cur_i:])
			if !proc_ok do break
			prev_token = .Number
			continue
		}

		// try parse operator
		op: proc(a, b: f64) -> f64 = nil
		op_pcd: u8 = 0
		cur_i, op, op_pcd, proc_ok = parse_op(input[cur_i:])
		if proc_ok {
			cur_opdata.op = op
			cur_opdata.op_pcd = op_pcd
			prev_token = .Operator

			// get previous operator precedence
			prev_op_pcd: u8 = 0
			for opdata in oplist {
				if prev_op_pcd < opdata.op_pcd && opdata.op != nil {
					prev_op_pcd = opdata.op_pcd
				}
			}
			// check operator precedence
			if oplist[prev_op_pcd].op != nil && prev_op_pcd <= op_pcd {
				// do calculation
				lhs := oplist[prev_op_pcd].num
				result = oplist[prev_op_pcd].op(lhs, num)
				// clear oplist
				clear_oplist()
				ok = true
			}

			// apply current op data
			oplist[op_pcd] = cur_opdata
			continue
		}
	} // end of for loop

	// final operation
	if prev_token == .Number {
		prev_op_pcd: u8 = 0
		for opdata in oplist {
			if prev_op_pcd < opdata.op_pcd && opdata.op != nil {
				prev_op_pcd = opdata.op_pcd
			}
		}
		if oplist[prev_op_pcd].op != nil {
			lhs := oplist[prev_op_pcd].num
			result = oplist[prev_op_pcd].op(lhs, num)
			ok = true
		} else {
			// unreachable?
		}
	} else {
		// math expression must end with number token
		ok = false; return
	}

	return
}
