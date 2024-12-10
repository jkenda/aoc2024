package main

import "core:os"
import "core:fmt"
import "core:strings"

Mode :: enum {
    Horizontal,
    Vertical,
    Diagonal,
    Cross,
}

Mask :: distinct [][]u8

MASKS_HORIZONTAL : []Mask = {
    {{ 'X', 'M', 'A', 'S' }},
    {{ 'S', 'A', 'M', 'X' }},
}
MASKS_VERTICAL : []Mask = {
    { {'X'}, {'M'}, {'A'}, {'S'} },
    { {'S'}, {'A'}, {'M'}, {'X'} },
}
MASKS_DIAGONAL : []Mask = {
    {{ 'X', '.', '.', '.' },
     { '.', 'M', '.', '.' },
     { '.', '.', 'A', '.' },
     { '.', '.', '.', 'S' }},

    {{ 'S', '.', '.', '.' },
     { '.', 'A', '.', '.' },
     { '.', '.', 'M', '.' },
     { '.', '.', '.', 'X' }},

    {{ '.', '.', '.', 'X' },
     { '.', '.', 'M', '.' },
     { '.', 'A', '.', '.' },
     { 'S', '.', '.', '.' }},

    {{ '.', '.', '.', 'S' },
     { '.', '.', 'A', '.' },
     { '.', 'M', '.', '.' },
     { 'X', '.', '.', '.' }},
}
MASKS_CROSS : []Mask = {
    {{ 'M', '.', 'M' },
     { '.', 'A', '.' },
     { 'S', '.', 'S' }},

    {{ 'M', '.', 'S' },
     { '.', 'A', '.' },
     { 'M', '.', 'S' }},

    {{ 'S', '.', 'M' },
     { '.', 'A', '.' },
     { 'S', '.', 'M' }},

    {{ 'S', '.', 'S' },
     { '.', 'A', '.' },
     { 'M', '.', 'M' }},
}

MASKS : map[Mode][]Mask = {
    .Horizontal = MASKS_HORIZONTAL,
    .Vertical   = MASKS_VERTICAL,
    .Diagonal   = MASKS_DIAGONAL,
    .Cross      = MASKS_CROSS,
}


Point :: struct {
    x: int,
    y: int,
}

main :: proc() {
    data, lines, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(data)
    assert(len(lines) > 0)

    { // part 1
        occur := find_occurences(lines, {
            .Horizontal,
            .Vertical,
            .Diagonal,
        })
        fmt.println(occur)
    }

    { // part 2
        occur := find_occurences(lines, { .Cross })
        fmt.println(occur)
    }
}

read_and_parse :: proc(path: string) -> (data: []u8, lines: []string, err: os.Error) {
    data = os.read_entire_file_or_err(path) or_return

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    lines = strings.split_lines(str)
    return
}

find_occurences :: proc(lines: []string, modes: []Mode) -> uint {
    occur : uint = 0

    for mode in modes {
        for mask in MASKS[mode] {
            for line, i in lines {
                for _, j in line {
                    start := Point{ x=j, y=i }
                    occur += match_mask(lines, mask, start)
                }
            }
        }
    }

    return occur
}

match_mask :: proc(lines: []string, mask: Mask, start: Point) -> uint {
    lines_height := len(lines)
    lines_width  := len(lines[0])

    mask_height := len(mask)
    mask_width  := len(mask[0])

    if start.y + mask_height > lines_height { return 0 }
    if start.x + mask_width  > lines_width  { return 0 }

    for i in 0..<mask_height {
        for j in 0..<mask_width {
            if mask[i][j] == '.' { continue }
            if mask[i][j] != lines[start.y+i][start.x+j] {
                return 0
            }
        }
    }
    return 1
}
