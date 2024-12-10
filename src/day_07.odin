package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:math"
import "core:strings"
import "core:strconv"

Equation:: struct {
    test_value: int,
    numbers: [dynamic]int,
}

operators: []proc(int, int) -> int

main :: proc() {
    equations, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(equations)

    add :: proc(a: int, b: int) -> int { return a + b }
    mul :: proc(a: int, b: int) -> int { return a * b }
    concat :: proc(a: int, b: int) -> int {
        log := math.log10(f64(b + 1))
        log = math.ceil(log)

        return a * int(math.pow10(log)) + b
    }

    could_possibly_be_true :: proc(test_value: int, result: int, numbers: []int) -> bool {
        if slice.is_empty(numbers) {
            return result == test_value
        }

        for op in operators {
            num := op(result, numbers[0])
            if could_possibly_be_true(test_value, num, numbers[1:]) {
                return true
            }
        }

        return false
    }

    { // part 1
        operators = { add, mul }
        sum := 0

        for eq in equations {
            is_true := could_possibly_be_true(eq.test_value, eq.numbers[0], eq.numbers[1:])
            sum += eq.test_value if is_true else 0
        }

        fmt.println(sum)
    }

    { // part 2
        operators = { add, mul, concat }
        sum := 0

        for eq in equations {
            is_true := could_possibly_be_true(eq.test_value, eq.numbers[0], eq.numbers[1:])
            sum += eq.test_value if is_true else 0
        }

        fmt.println(sum)
    }
}

read_and_parse :: proc(path: string) -> (equations: [dynamic]Equation, err: os.Error) {
    data := os.read_entire_file_or_err(path) or_return
    defer delete(data)

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    for line in strings.split_lines_iterator(&str) {
        s := strings.split(line, ":")
        assert(len(s) == 2)
        str_l, str_r := s[0], s[1]

        test_value := strconv.atoi(str_l)
        numbers := make([dynamic]int)

        for str_n in strings.split_iterator(&str_r, " ") {
            append(&numbers, strconv.atoi(str_n))
        }

        append(&equations, Equation{ test_value, numbers })
    }

    return
}
