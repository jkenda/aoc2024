package main

import "core:os"
import "core:fmt"
import "core:strings"

Map :: distinct []string
Position :: distinct [2]int
Position_Set :: distinct map[Position]struct{}

steps : []Position = {
    { 0, -1 },
    { 0,  1 },
    { -1, 0 },
    {  1, 0 },
}

main :: proc() {
    data, topographic_map, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(data)

    starting_positions := find_starting_positions(topographic_map)
    defer delete(starting_positions)

    is_in_map :: proc(topographic_map: Map, position: Position) -> bool {
        if position.x < 0 || position.y < 0 { return false }
        return position.y < len(topographic_map) && position.x < len(topographic_map[0])
    }

    get_trailhead_score :: proc(topographic_map: Map, position: Position, visited: ^Position_Set = nil) -> (score: uint) {
        if visited != nil {
            if _, ok := visited[position]; ok { return 0 }
            visited[position] = {}
        }

        height := topographic_map[position.y][position.x]
        if height == '9' { return 1 }

        for step in steps {
            next := position + step
            if !is_in_map(topographic_map, next) { continue }

            next_height := topographic_map[next.y][next.x]
            if next_height != height + 1 { continue }

            score += get_trailhead_score(topographic_map, next, visited)
        }

        return
    }

    { // part 1
        visited: Position_Set
        defer delete(visited)

        score_sum : uint = 0

        for start in starting_positions {
            clear(&visited)
            score_sum += get_trailhead_score(topographic_map, start, &visited)
        }

        fmt.println(score_sum)
    }

    { // part 2
        score_sum : uint = 0

        for start in starting_positions {
            score_sum += get_trailhead_score(topographic_map, start)
        }

        fmt.println(score_sum)
    }
}

read_and_parse :: proc(path: string) -> (data: []u8, topographic_map: Map, err: os.Error) {
    data = os.read_entire_file_or_err(path) or_return

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    topographic_map = cast(Map)strings.split_lines(str)
    return
}

find_starting_positions :: proc(topographic_map: Map) -> (starting_positions: [dynamic]Position) {
    for line, y in topographic_map {
        for c, x in line {
            if c == '0' {
                append(&starting_positions, Position{ x, y })
            }
        }
    }

    return
}
