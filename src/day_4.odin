package main

import "core:os"
import "core:fmt"
import "core:slice"
import "core:strings"

XMAS :: "XMAS"

Point :: struct {
    x: int,
    y: int,
}

Mode :: enum {
    Horizontal,
    Vertical,
    Diagonal,
}

main :: proc() {
    data, lines, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(data)

    { // part 1
        occur : uint = 0
        for line, i in lines {
            for _, j in line {
                point := Point{ x=j, y=i }

                occur += find(.Horizontal, lines, point)
                occur += find(.Vertical, lines, point)
                occur += find(.Diagonal, lines, point)
            }
        }

        fmt.println(occur)
    }
}

read_and_parse :: proc(path: string) -> (data: []u8, lines: []string, err: os.Error)
{
    data = os.read_entire_file_or_err(path) or_return

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    lines = strings.split_lines(str)
    return
}

find :: proc(mode: Mode, lines: []string, start: Point) -> uint {
    occur : uint = 0

    switch mode {
    case .Horizontal:
        line := lines[start.y]
        end_x := start.x + len(XMAS)
        if end_x > len(lines[0]) { return 0 }

        occur += occurrences(line[start.x:end_x])

    case .Vertical:
        end_y := start.y + len(XMAS)
        if end_y > len(lines) { return 0 }

        str: [len(XMAS)]u8
        for line, idx in lines[start.y:end_y] {
            str[idx] = line[start.x]
        }

        occur += occurrences(str[:])

   case .Diagonal:
        end_x := start.x + len(XMAS)
        end_y := start.y + len(XMAS)
        if end_y > len(lines) { return 0 }
        if end_x > len(lines[0]) { return 0 }

        str: [len(XMAS)]u8
        {
            for idx in 0..<len(XMAS) {
                str[idx] = lines[start.y + idx][start.x + idx]
            }

            occur += occurrences(str[:])
        }

        {
            for idx in 0..<len(XMAS) {
                str[idx] = lines[start.y + idx][end_x - idx - 1]
            }

            occur += occurrences(str[:])
        }
    }

    return occur
}

occurrences :: proc {
    occurrences_in_string,
    occurrences_in_bytes,
}

occurrences_in_string :: proc(word: string) -> (occur: uint) {
    occur += 1 if strings.starts_with(word, XMAS) else 0

    reversed := strings.reverse(word)
    defer delete(reversed)

    occur += 1 if strings.starts_with(reversed, XMAS) else 0
    return
}

occurrences_in_bytes :: proc(word: []u8) -> (occur: uint) {
    occur += string(word[:]) == XMAS
    slice.reverse(word[:])
    occur += string(word[:]) == XMAS
    return
}
