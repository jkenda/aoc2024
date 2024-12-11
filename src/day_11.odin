package main

import "core:os"
import "core:fmt"
import "core:math"
import "core:strings"
import "core:strconv"

Stone :: distinct uint

main :: proc() {
    stones, err := read_and_parse(os.args[1])
    if err != nil {
        fmt.println(err, ":", os.error_string(err))
        return
    }
    defer delete(stones)

    num_digits :: proc(stone: Stone) -> uint {
        using math
        return uint(ceil(log10(f32(stone + 1))))
    }

    split_stone :: proc(stone: Stone) -> [2]Stone {
        using strconv
        @(static) buf: [256]u8

        str := itoa(buf[:], cast(int)stone)
        return {
            cast(Stone)atoi(str[:len(str)/2]),
            cast(Stone)atoi(str[len(str)/2:]),
        }
    }

    apply_rules :: proc(stone: Stone) -> (new_stone: []Stone) {
        @(static) buf: [2]Stone 

        if stone == 0 {
            // - If the stone is engraved with the number 0,
            //   it is replaced by a stone engraved with the number 1.
            buf[0] = 1
            new_stone = buf[:1]
        }
        else if num_digits(stone) %% 2 == 0 {
            // - If the stone is engraved with a number that has an even number of digits, it is replaced by two stones.
            //  The left half of the digits are engraved on the new left stone,
            //  and the right half of the digits are engraved on the new right stone.
            //  (The new numbers don't keep extra leading zeroes: 1000 would become stones 10 and 0.)
            buf = split_stone(stone)
            new_stone = buf[:]
        }
        else {
            // - If none of the other rules apply, the stone is replaced by a new stone;
            //  the old stone's number multiplied by 2024 is engraved on the new stone.
            buf[0] = stone * 2024
            new_stone = buf[:1]
        }

        return
    }

    { // part 1
        BLINKS :: 25

        // after blinking 25 times
        for num_blinks in 0..<BLINKS {
            for i := 0; i < len(stones); {
                replacements := apply_rules(stones[i])
                defer i += len(replacements)

                stones[i] = replacements[0]
                if len(replacements) > 1 {
                    inject_at(&stones, i + 1, replacements[1])
                }
            }
        }

        fmt.println(len(stones))
    }
}

read_and_parse :: proc(path: string) -> (stones: [dynamic]Stone, err: os.Error) {
    data := os.read_entire_file_or_err(path) or_return
    defer delete(data)

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    for str_stone in strings.split_iterator(&str, " ") {
        stone, ok := strconv.parse_uint(str_stone)
        assert(ok)

        append(&stones, cast(Stone)stone)
    }

    return
}
