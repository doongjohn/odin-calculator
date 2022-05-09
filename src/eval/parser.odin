package eval

import "core:fmt"
import "core:math"
import "core:strings"
import "core:strconv"
import "core:unicode/utf8"

@(private)
@(require_results)
parse_const :: proc(index: ^int, str: string) -> (num: f64, ok: bool = true) {
	// parse predefined constants
	// return:
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

@(private)
@(require_results)
parse_number :: proc(index: ^int, str: string) -> (num: f64, ok: bool = true) {
	// parse string as f64 number
	// NOTE: `+`, `-` prefix is part of the number
	// return:
	//     num => parsed number
	//     ok  => is an input successfully parsed as f64

	length := len(str)
	is_prefixed := strings.index_byte("+-", str[0]) >= 0
	if is_prefixed && length == 1 {
		ok = false; return
	}
	if is_prefixed && length > 1 && strings.index_byte("+-", str[1]) >= 0 {
		ok = false; return
	}

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

	// parse success
	index^ += end
	return
}

@(private)
@(require_results)
parse_op :: proc(index: ^int, str: string) -> (op: proc(a, b: f64) -> f64, op_pcd: u8, ok: bool = true) {
	// parse operator
	// return:
	//     op     => operation function
	//     op_pcd => operation precedence
	//     ok     => is parentheses has a matching pair

	operators: #soa[5]struct {
		str: string,
		pcd: u8,
		func: proc(a, b: f64) -> f64,
	}
	operators[0] = {
		"+", 0,
		proc(a, b: f64) -> f64 {
			fmt.printf("{} + {}\n", a, b);
			return a + b
		},
	}
	operators[1] = {
		"-", 0,
		proc(a, b: f64) -> f64 {
			fmt.printf("{} - {}\n", a, b);
			return a - b
		},
	}
	operators[2] = {
		"*", 1,
		proc(a, b: f64) -> f64 {
			fmt.printf("{} * {}\n", a, b);
			return a * b
		},
	}
	operators[3] = {
		"/", 1,
		proc(a, b: f64) -> f64 {
			fmt.printf("{} / {}\n", a, b);
			return a / b
		},
	}
	operators[4] = {
		"^", 2,
		proc(a, b: f64) -> f64 {
			fmt.printf("{} ^ {}\n", a, b);
			return math.pow(a, b)
		},
	}

	for operator, i in operators {
		if operator.str == str[:len(operator.str)] {
			fmt.printf("parsed: op = {}\n", operator.str)
			op_pcd = operator.pcd
			op = operator.func
			index^ += len(operator.str)
			return
		}
	}

	ok = false; return
}

@(private)
@(require_results)
parse_paren :: proc(index: ^int, str: string) -> (expr_sign: f64, expr_start, expr_end: int, ok: bool = true) {
	// parse parentheses
	// return:
	//     expr_sign  => sign of this expression
	//     expr_start => index where the inner expression is started
	//     expr_end   => index where the inner expression is ended
	//     ok         => is parentheses has a matching pair

	length := len(str)
	if length <= 1 {
		ok = false; return
	}

	expr_sign = 1
	expr_start = index^ + 1
	if str[:2] == "-(" {
		expr_sign = -1
		expr_start += 1
	} else if str[:2] == "+(" {
		expr_start += 1
	} else if str[0] != '(' {
		ok = false; return
	}

	open_count := 1
	for end := expr_start - index^; end < length; end += 1 {
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
