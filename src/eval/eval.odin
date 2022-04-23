package eval

import "core:fmt"
import "core:math"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"

parse_number :: proc(index: ^int, str: string) -> (num: f64, ok: bool) {
	// parse string as f64 number
	// NOTE: `+`, `-` prefix is part of the number
	// return:
	//     end => index where parsing is ended
	//     num => parsed number
	//     ok  => is an input successfully parsed as f64

	ok = true
	end := 0
	length := len(str)
	is_prefixed := strings.index_byte("+-", str[0]) >= 0

	if is_prefixed && (length == 1 || strings.index_byte(".0123456789", str[1]) < 0) {
		ok = false; return
	}

	for end < length {
		end += 1
		parse_ok := false
		// HACK: can be optimized
		num, parse_ok = strconv.parse_f64(str[:end])
		if !parse_ok {
			if end == 1 {
				// cannot parse as float
				ok = false; return
			} else {
				// parse ended
				index^ += end - 1
				return
			}
		}
	}
	return
}

parse_const :: proc(index: ^int, str: string) -> (num: f64, ok: bool) {
	// parse predefined constants
	// return:
	//     end => index where parsing is ended
	//     num => value of the constant
	//     ok  => is an input successfully parsed as constant

	ok = true
	end := 0
	length := len(str)
	is_prefixed := strings.index_byte("+-", str[0]) >= 0

	if length == 0 || strings.index_byte(".0123456789*/^", str[0]) >= 0 {
		ok = false; return
	}

	start := 0
	sign: f64 = 1
	if is_prefixed {
		start = 1
		end = 1
		if str[0] == '-' do sign = -1
	}

	char_is_alphabet :: proc(c: u8) -> bool {
		return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
	}
	char_is_number :: proc(c: u8) -> bool {
		return c >= '0' && c <= '9'
	}

	for end < length - 1 {
		if str[end] == ' ' do break
		if !char_is_alphabet(str[end]) || !char_is_number(str[end]) {
			break
		}
		end += 1
	}

	switch str[start:end] {
	case "pi" : num = math.PI
	case "tau": num = math.TAU
	case "e"  : num = math.E
	}
	num *= sign

	if num != 0 {
		index^ += end
		return
	}
	ok = false; return
}

parse_op :: proc(index: ^int, str: string) -> (op: proc(a, b: f64) -> f64, op_pcd: u8, ok: bool) {
	// parse operator
	// return:
	//     end    => index where parsing is ended
	// 	   op     => operation function
	// 	   op_pcd => operation precedence
	//     ok     => is parentheses has a matching pair

	ok = true
	end := 0
	length := len(str)

	ops := [?]string{ "+", "-", "*", "/", "^" }
	op_pcds := [?]u8 { 0, 0, 1, 1, 2 }
	op_procs := [?]proc(a, b: f64) -> f64 {
		proc(a, b: f64) -> f64 { fmt.println("add"); return a + b },
		proc(a, b: f64) -> f64 { fmt.println("sub"); return a - b },
		proc(a, b: f64) -> f64 { fmt.println("mul"); return a * b },
		proc(a, b: f64) -> f64 { fmt.println("div"); return a / b },
		proc(a, b: f64) -> f64 { fmt.println("pow"); return math.pow(a, b) },
	}

	for opstr, i in ops {
		if opstr == str[:len(opstr)] {
			fmt.printf("op = {}\n", opstr)
			op = op_procs[i]
			op_pcd = op_pcds[i]
			index^ += len(opstr)
			return
		}
	}

	ok = false; return
}

parse_paren :: proc(index: ^int, str: string) -> (ok: bool) {
	// parse parentheses
	// return:
	//     i  => index where parsing is ended
	//     ok => is parentheses has a matching pair
	// TODO: include sign

	ok = true
	end := 0
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

	ok = open_count == 0
	index^ += end + 1
	return
}

Op_Data :: struct {
	num: f64,
	op: proc(a, b: f64) -> f64,
	op_pcd: u8,
}

// TODO: make eval function
evaluate :: proc(input: string) -> (result: f64, ok: bool) {
	TokenType :: enum {
		None,
		Number,
		Operator,
	}

	oplist := [3]Op_Data {
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
	cur_opdata := Op_Data{ num = 0, op = nil, op_pcd = 0 }
	prev_token: TokenType = .None

	fmt.printf("length = {}\n", length)
	for cur_i < length {
		cur_c = input[cur_i]

		// ignore white space
		if cur_c == ' ' {
			cur_i += 1
			continue
		}

		if prev_token != .Number {
			// try parse number literal
			fmt.println("try parse number")
			num, proc_ok = parse_number(&cur_i, input[cur_i:])
			if proc_ok {
				cur_opdata.num = num
				fmt.printf("num = {}\n", num)
				prev_token = .Number
				continue
			}

			// try parse constant
			fmt.println("try parse constant")
			num, proc_ok = parse_const(&cur_i, input[cur_i:])
			if proc_ok {
				cur_opdata.num = num
				fmt.printf("num = {}\n", num)
				prev_token = .Number
				continue
			}

			// try parse parentheses
			fmt.println("try parse paren")
			proc_ok = parse_paren(&cur_i, input[cur_i:])
			if proc_ok {
				// try evaluate expression
				num, proc_ok = evaluate(input[cur_i:])
				fmt.printf("num = {}\n", num)
				if !proc_ok do break
				prev_token = .Number
				continue
			}
		} else {
			if cur_i == length - 1 do break

			// try parse operator
			fmt.println("try parse operator")
			op: proc(a, b: f64) -> f64 = nil
			op_pcd: u8 = 0
			op, op_pcd, proc_ok = parse_op(&cur_i, input[cur_i:])
			if proc_ok {
				cur_opdata.op = op
				cur_opdata.op_pcd = op_pcd
				fmt.printf("op_pcd = {}\n", op_pcd)
				prev_token = .Operator

				// get previous operator precedence
				prev_op_pcd: u8 = 0
				for i := 2; i >= 0; i -= 1 {
					opdata := oplist[i]
					if prev_op_pcd < opdata.op_pcd && opdata.op != nil {
						prev_op_pcd = opdata.op_pcd
					}
				}
				// BUG: ok i need to do all previous operation
				// check operator precedence
				if oplist[prev_op_pcd].op != nil && prev_op_pcd == op_pcd {
					// do calculation
					prev_op := oplist[prev_op_pcd].op
					lhs := oplist[prev_op_pcd].num
					rhs := cur_opdata.num
					fmt.printf("lhs = {}, rhs = {}\n", lhs, rhs)
					cur_opdata.num = prev_op(lhs, rhs)
					// clear oplist
					clear_oplist()
				}

				// apply current op data
				oplist[op_pcd] = cur_opdata
				continue
			}

			// TODO: error consecutive numbers
			fmt.println("consecutive numbers!")
			ok = false; return
		}
	} // end of for loop

	// final operation
	if prev_token == .Number {
		fmt.println("calculate!")
		prev_op_pcd: u8 = 0
		for i := 2; i >= 0; i -= 1 {
			opdata := oplist[i]
			if prev_op_pcd < opdata.op_pcd && opdata.op != nil {
				prev_op_pcd = opdata.op_pcd
			}
		}
		if oplist[prev_op_pcd].op != nil {
			lhs := oplist[prev_op_pcd].num
			fmt.printf("lhs = {}, rhs = {}\n", lhs, num)
			result = oplist[prev_op_pcd].op(lhs, num)
			ok = true
		} else {
			// unreachable?
		}
	} else {
		// math expression must end with the number token
		fmt.println("calculate failed!")
		ok = false; return
	}

	return
}
