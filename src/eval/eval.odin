package eval

import "core:fmt"
import "core:math"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"

@(require_results)
parse_const :: proc(index: ^int, str: string) -> (num: f64, ok: bool = true) {
	// parse predefined constants
	// return:
	//     end => index where parsing is ended
	//     num => value of the constant
	//     ok  => is an input successfully parsed as constant

	start := 0
	sign: f64 = 1
	if strings.index_byte("+-", str[0]) >= 0 {
		start = 1
		if str[0] == '-' do sign = -1
	}

	constants :: [?]string {
		"pi",
		"tau",
		"e",
	}
	values := [?]f64 {
		math.PI,
		math.TAU,
		math.E,
	}

	for name, i in constants {
		if len(str) < len(name) + start do continue
		if str[start:len(name) + start] == name {
			num = values[i] * sign
			index^ += len(name)
			return
		}
	}

	ok = false; return
}

@(require_results)
parse_number :: proc(index: ^int, str: string) -> (num: f64, ok: bool = true) {
	// parse string as f64 number
	// NOTE: `+`, `-` prefix is part of the number
	// return:
	//     end => index where parsing is ended
	//     num => parsed number
	//     ok  => is an input successfully parsed as f64

	length := len(str)
	is_prefixed := strings.index_byte("+-", str[0]) >= 0

	end := 0
	parse_ok := false
	for end < length {
		end += 1
		num, parse_ok = strconv.parse_f64(str[:end]) // HACK: can be optimized
		if !parse_ok {
			if end == 1 {
				// cannot parse as float
				ok = false; return
			} else {
				// parse success
				index^ += end - 1
				return
			}
		}
	}
	index^ += end
	return
}

@(require_results)
parse_op :: proc(index: ^int, str: string) -> (op: proc(a, b: f64) -> f64, op_pcd: u8, ok: bool = true) {
	// parse operator
	// return:
	//     end    => index where parsing is ended
	// 	   op     => operation function
	// 	   op_pcd => operation precedence
	//     ok     => is parentheses has a matching pair

	length := len(str)
	end := 0

	ops := [?]string{ "+", "-", "*", "/", "^" }
	op_pcds := [?]u8 { 0, 0, 1, 1, 2 }
	op_procs := [?]proc(a, b: f64) -> f64 {
		proc(a, b: f64) -> f64 { fmt.printf("{} + {}\n", a, b); return a + b },
		proc(a, b: f64) -> f64 { fmt.printf("{} - {}\n", a, b); return a - b },
		proc(a, b: f64) -> f64 { fmt.printf("{} * {}\n", a, b); return a * b },
		proc(a, b: f64) -> f64 { fmt.printf("{} / {}\n", a, b); return a / b },
		proc(a, b: f64) -> f64 { fmt.printf("{} ^ {}\n", a, b); return math.pow(a, b) },
	}

	for opstr, i in ops {
		if opstr == str[:len(opstr)] {
			fmt.printf("parsed: op = {}\n", opstr)
			op = op_procs[i]
			op_pcd = op_pcds[i]
			index^ += len(opstr)
			return
		}
	}

	ok = false; return
}

@(require_results)
parse_paren :: proc(index: ^int, str: string) -> (expr_end: int, ok: bool = true) {
	// parse parentheses
	// return:
	//     i  => index where parsing is ended
	//     ok => is parentheses has a matching pair
	// TODO: include sign

	length := len(str)

	if length < 2 || str[0] != '(' {
		ok = false; return
	}

	end := 0
	open_count := 1
	for end < length - 1 {
		end += 1
		switch str[end] {
		case '(': open_count += 1
		case ')': open_count -= 1
		}
		if open_count < 0 {
			ok = false; return
		}
		if open_count == 0 {
			expr_end = index^ + end
			index^ += end + 1
			return
		}
	}

	ok = false; return
}

TokenType :: enum {
	None,
	Number,
	Operator,
}

Op_Data :: struct {
	num: f64,
	op: proc(a, b: f64) -> f64,
	op_pcd: u8,
}

evaluate :: proc(input: string) -> (result: f64, ok: bool = true) {
	oplist := [3]Op_Data {
		Op_Data{}, // operator precedence 0
		Op_Data{}, // operator precedence 1
		Op_Data{}, // operator precedence 2
	}
	context.user_ptr = &oplist

	length := len(input)
	prev_token: TokenType = .None
	prev_op_pcd: u8 = 0
	cur_i: int = 0
	cur_c: u8 = 0
	cur_opdata := Op_Data{}

	oplist_calculate :: proc(oplist: []Op_Data, prev_op_pcd: u8, cur_opdata: ^Op_Data) {
		// calculate all operations from the highest precedence
		// -----------------
		// 1 + 2 * 2 ^ 3 + 1
		// -----------------
		// oplist[0]  : 1+
		// oplist[1]  : 2*
		// oplist[2]  : 2^
		// cur_opdata : 3+
		// -----------------
		// last opdata `3 + 1` will be
		// calculated at the end of the evaluate function
		prev_op_pcd := prev_op_pcd
		prev_opdata := Op_Data{}
		i := prev_op_pcd
		for {
			prev_opdata = oplist[prev_op_pcd]
			if prev_opdata.op != nil {
				// calculate
				cur_opdata.num = prev_opdata.op(prev_opdata.num, cur_opdata.num)
				// clear previous op data
				oplist[prev_op_pcd] = Op_Data{}
			}
			if prev_op_pcd == 0 do break
			prev_op_pcd -= 1
		}
	}

	@(require_results)
	parse_token_number :: proc(input: string, cur_i: ^int, cur_opdata: ^Op_Data) -> (ok: bool = true) {
		num: f64 = 0
		proc_ok := false

		// try parse constant
		num, proc_ok = parse_const(cur_i, input[cur_i^:])
		if proc_ok {
			cur_opdata.num = num
			fmt.printf("parsed: constant = {}\n", num)
			return
		}

		// try parse number literal
		num, proc_ok = parse_number(cur_i, input[cur_i^:])
		if proc_ok {
			cur_opdata.num = num
			fmt.printf("parsed: number literal = {}\n", num)
			return
		}

		// try parse parentheses
		paren_start := cur_i^ + 1
		paren_end := 0
		paren_end, proc_ok = parse_paren(cur_i, input[cur_i^:])
		if proc_ok {
			fmt.println("parsed: parentheses")
			// NOTE: it may cause stack overflow
			num, proc_ok = evaluate(input[paren_start:paren_end])
			if proc_ok {
				fmt.println("(expression ended)")
				cur_opdata.num = num
				return
			} else {
				fmt.println("error: invalid expression!")
				ok = false; return
			}
		}

		ok = false; return
	}

	@(require_results)
	parse_token_operator :: proc(oplist: []Op_Data, input: string, cur_i: ^int, cur_opdata: ^Op_Data, prev_op_pcd: ^u8) -> (ok: bool = true) {
		proc_ok := false
		op: proc(a, b: f64) -> f64 = nil
		op_pcd: u8 = 0

		op, op_pcd, proc_ok = parse_op(cur_i, input[cur_i^:])
		if proc_ok {
			cur_opdata.op = op
			cur_opdata.op_pcd = op_pcd

			prev_opdata := oplist[prev_op_pcd^]
			if prev_op_pcd^ >= op_pcd {
				oplist_calculate(oplist, prev_op_pcd^, cur_opdata)
			}

			// apply to oplist
			oplist[op_pcd] = cur_opdata^

			// set previous data
			prev_op_pcd^ = op_pcd
			return
		}

		ok = false; return
	}

	fmt.printf("length = {}\n", length)
	for cur_i < length {
		fmt.printf("[{}]: %c\n", cur_i, input[cur_i])

		// ignore white space
		if input[cur_i] == ' ' {
			cur_i += 1
			continue
		}

		if prev_token != .Number {
			if parse_ok := parse_token_number(input, &cur_i, &cur_opdata); parse_ok {
				prev_token = .Number
				continue
			} else {
				fmt.println("error: number expected!")
				ok = false; return
			}
		}

		if prev_token == .Number {
			if parse_ok := parse_token_operator(oplist[:], input, &cur_i, &cur_opdata, &prev_op_pcd); parse_ok {
				prev_token = .Operator
				continue
			} else {
				fmt.println("error: unknown operator!")
				ok = false; return
			}
		}

		// end of for loop
	}

	// final calculation
	if prev_token == .Number {
		fmt.println("final calculation")
		oplist_calculate(oplist[:], prev_op_pcd, &cur_opdata)
		fmt.printf("result = {}\n", cur_opdata.num)
		result = cur_opdata.num
		return
	} else {
		// TODO: make error enum
		fmt.println("error: expression must end with a number!")
		ok = false; return
	}

	return
}
