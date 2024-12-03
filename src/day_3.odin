package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:unicode"

main :: proc() {
    data, err := os.read_entire_file_or_err(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    { // part 1
        sum : uint = 0

        for {
            i_mul := strings.index(str, "mul(")
            if i_mul == -1 { break }
            str = str[i_mul:]

            i_opening := len("mul")
            i_comma := strings.index(str, ",")
            i_closing := strings.index(str, ")")
            i_mul_next := strings.index(str[i_opening:], "mul(")

            defer str = str[i_opening:]

            i_1st_begin := i_opening + 1
            i_1st_end   := i_comma

            i_2nd_begin := i_comma + 1
            i_2nd_end   := i_closing

            // illegal format
            if i_1st_begin > i_1st_end { continue }
            if i_2nd_begin > i_2nd_end { continue }

            len_1st := i_1st_end - i_1st_begin
            len_2nd := i_2nd_end - i_2nd_begin

            // 1-3 digit numbers
            if len_1st < 1 || len_1st > 3 { continue }
            if len_2nd < 1 || len_2nd > 3 { continue }

            num_1st, ok1 := strconv.parse_uint(str[i_1st_begin:i_1st_end])
            num_2nd, ok2 := strconv.parse_uint(str[i_2nd_begin:i_2nd_end])

            // error parsing
            if !ok1 || !ok2 { continue }

            sum += num_1st * num_2nd
        }

        fmt.println(sum)
    }

    // TODO: part 2

    defer delete(data)
}
