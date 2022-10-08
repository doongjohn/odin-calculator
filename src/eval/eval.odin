package eval

import "core:fmt"

@(private = "file")
TokenType :: enum {
	None,
	Number,
	Operator,
}

@(private = "file")
Op_Data :: struct {
	num: f64,
	op: proc(a, b: f64) -> f64,
	op_pcd: u8,
}

@(private = "file")
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

@(private = "file")
@(require_results)
parse_token_number :: proc(input: string, cur_i: ^int, cur_opdata: ^Op_Data) -> (ok: bool = true) {
	num: f64 = 0
	parse_ok := false

	// try parse parentheses
	paren_sign := 0.0
	paren_start := 0
	paren_end := 0
	paren_sign, paren_start, paren_end, parse_ok = parse_paren(cur_i, input[cur_i^:])
	if parse_ok {
		// NOTE: it may cause stack overflow if there are too many nested parentheses
		num, parse_ok = evaluate(input[paren_start:paren_end])
		if parse_ok {
			cur_opdata.num = num * paren_sign
			return
		} else {
			// TODO: return proper error
			fmt.println("ERR: invalid expression!")
			ok = false; return
		}
	}

	// try parse constant
	num, parse_ok = parse_const(cur_i, input[cur_i^:])
	if parse_ok {
		cur_opdata.num = num
		return
	}

	// try parse number literal
	num, parse_ok = parse_number(cur_i, input[cur_i^:])
	if parse_ok {
		cur_opdata.num = num
		return
	}

	ok = false; return
}

@(private = "file")
@(require_results)
parse_token_function :: proc(input: string, cur_i: ^int, cur_opdata: ^Op_Data) -> (ok: bool = true) {
	// TODO: impl this
	return
}

@(private = "file")
@(require_results)
parse_token_operator :: proc(oplist: []Op_Data, input: string, cur_i: ^int, cur_opdata: ^Op_Data, prev_op_pcd: ^u8) -> (ok: bool = true) {
	op: proc(a, b: f64) -> f64 = nil
	op_pcd: u8 = 0
	parse_ok := false

	op, op_pcd, parse_ok = parse_op(cur_i, input[cur_i^:])
	if parse_ok {
		cur_opdata.op = op
		cur_opdata.op_pcd = op_pcd

		// if the current precedence is lower than or equal to
		// the previous precedence, calculate all operations in the oplist
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

@(require_results)
evaluate :: proc(input: string) -> (result: f64, ok: bool = true) {
	prev_token: TokenType = .None
	prev_op_pcd: u8
	cur_opdata: Op_Data
	oplist := [3]Op_Data {
		Op_Data{}, // operator precedence 0
		Op_Data{}, // operator precedence 1
		Op_Data{}, // operator precedence 2
	}

	length := len(input)
	cur_i := 0
	for cur_i < length {
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
				// TODO: return proper error
				// also if the number was a result of an expression, don't print this
				fmt.println("ERR: number is expected at position", cur_i)
				ok = false; return
			}
		}

		if prev_token == .Number {
			if parse_ok := parse_token_operator(oplist[:], input, &cur_i, &cur_opdata, &prev_op_pcd); parse_ok {
				prev_token = .Operator
				continue
			} else {
				// TODO: return proper error
				fmt.println("ERR: operator is expected at position", cur_i)
				ok = false; return
			}
		}

		// end of for loop
	}

	// final calculation
	if prev_token == .Number {
		oplist_calculate(oplist[:], prev_op_pcd, &cur_opdata)
		result = cur_opdata.num
		return
	} else {
		// TODO: make error enum
		fmt.println("ERR: expression must end with a number")
		ok = false; return
	}
}
