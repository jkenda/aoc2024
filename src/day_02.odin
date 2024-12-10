package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

Dir :: enum {
    Rising,
    Falling,
}

Report :: distinct [dynamic]int

read_and_parse :: proc(path: string) -> (reports: [dynamic]Report, err: os.Error) {
    data := os.read_entire_file_or_err(path) or_return
    defer delete(data)

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    for &str_report, i in strings.split_lines(str) {
        append(&reports, make(Report))

        for str_level in strings.fields_iterator(&str_report) {
            level := strconv.atoi(str_level)
            append(&reports[i], level)
        }
    }

    return
}

is_report_safe :: proc(report: []int) -> bool {
    level_prev: int
    dir: Dir

    for level, idx in report {
        defer level_prev = level

        switch idx {
        case 0:
        case 1:
            dir = .Rising if level > level_prev else .Falling
            fallthrough
        case:
            // Any two adjacent levels differ by at least one and at most three.
            diff := abs(level - level_prev)
            if diff < 1 || diff > 3 { return false }

            // The levels are either all increasing or all decreasing.
            if dir == .Rising  && level < level_prev { return false }
            if dir == .Falling && level > level_prev { return false }
        }
    }

    return true
}

main :: proc() {
    reports, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }

    { // part 1
        sum_safe : uint = 0

        for report in reports {
            if is_report_safe(report[:]) {
                sum_safe += 1
            }
        }

        fmt.println(sum_safe)
    }

    { // part 2
        sum_safe : uint = 0

        for &report in reports {
            for level, idx in report {
                ordered_remove(&report, idx)
                defer inject_at(&report, idx, level)

                if is_report_safe(report[:]) {
                    sum_safe += 1
                    break
                }
            }
        }

        fmt.println(sum_safe)
    }
}
