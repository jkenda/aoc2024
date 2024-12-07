package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"

Equation:: struct {
    test_value: int,
    numbers: [dynamic]int,
}

main :: proc() {
    equations, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(equations)

    could_possibly_be_true :: proc(test_value: int, result: int, numbers: []int) -> bool {
        if slice.is_empty(numbers) {
            return result == test_value
        }

        return could_possibly_be_true(test_value, result + numbers[0], numbers[1:]) ||
               could_possibly_be_true(test_value, result * numbers[0], numbers[1:])
    }

    { // part 1
        sum := 0

        for eq in equations {
            assert(len(eq.numbers) > 0)
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
