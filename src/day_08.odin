package main

import "core:os"
import "core:fmt"
import "core:math"
import "core:strings"

Map           :: distinct []string
Position      :: distinct [2]int
Position_List :: distinct [dynamic]Position
Position_Set  :: distinct map[Position]struct{}
Freq_Map      :: distinct map[rune]Position_List

delete_freq_map :: proc(m: Freq_Map) {
    for _, pos_list in m {
        delete(pos_list)
    }
    delete(m)
}

main :: proc() {
    data, antenna_map, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(data)

    antenna_positions := get_antenna_positions(antenna_map)
    defer delete_freq_map(antenna_positions)

    is_in_map :: proc(antenna_map: Map, antenna_position: Position) -> bool {
        if antenna_position.x < 0 || antenna_position.y < 0 { return false }
        if antenna_position.x >= len(antenna_map[0]) { return false }
        if antenna_position.y >= len(antenna_map) { return false }
        return true
    }

    for_all_antenna_permutations :: proc(
        antenna_map: Map,
        antenna_positions: Freq_Map, 
        antinodes_set: ^Position_Set,
        p: proc(antenna_map: Map, antinodes_set: ^Position_Set, antennas: [2]Position)
    ) {
        for freq, positions in antenna_positions {
            // search all permutations of 2 positions
            for pos1, i in positions {
                for pos2 in positions[:i] {
                    // call proc p on permutation
                    p(antenna_map, antinodes_set, { pos1, pos2 })
                }
            }
        }
    }

    { // part 1
        antinodes_set: Position_Set
        defer delete(antinodes_set)

        for_all_antenna_permutations(antenna_map, antenna_positions, &antinodes_set,
            proc(antenna_map: Map, antinodes_set: ^Position_Set, antennas: [2]Position) {
                distance := antennas[1] - antennas[0]

                antinodes := []Position{
                    distance[0] - distance,
                    antennas[1] + distance,
                }

                for pos in antinodes {
                    if is_in_map(antenna_map, pos) {
                        antinodes_set[pos] = {}
                    }
                }
            })

        fmt.println(len(antinodes_set))
    }

    { // part 2
        antinodes_set: Position_Set
        defer delete(antinodes_set)

        for_all_antenna_permutations(antenna_map, antenna_positions, &antinodes_set,
            proc(antenna_map: Map, antinodes_set: ^Position_Set, antennas: [2]Position) {
                distance := antennas[1] - antennas[0]
                distance /= math.gcd(distance.x, distance.y)

                for pos := antennas[1]; is_in_map(antenna_map, pos); pos -= distance {
                    antinodes_set[pos] = {}
                }
                for pos := antennas[0]; is_in_map(antenna_map, pos); pos += distance {
                    antinodes_set[pos] = {}
                }
            })

        fmt.println(len(antinodes_set))
    }
}

read_and_parse :: proc(path: string) -> (data: []u8, antenna_map: Map, err: os.Error) {
    data = os.read_entire_file_or_err(path) or_return

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    antenna_map = cast(Map)strings.split_lines(str)
    return
}

get_antenna_positions :: proc(antenna_map: Map) -> (positions: Freq_Map) {
    for line, y in antenna_map {
        for c, x in line {
            if c == '.' { continue }

            _, ok := positions[c]
            if (!ok) {
                positions[c] = make(Position_List)
            }

            append(&positions[c], Position{ x, y })
        }
    }

    return
}
