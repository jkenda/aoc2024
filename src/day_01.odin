package main

import "core:os"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:fmt"

ids_left  : [dynamic]int
ids_right : [dynamic]int

read_and_parse :: proc(path: string) {
    data, ok := os.read_entire_file(path, context.allocator)
    if !ok {
        fmt.println("Can't read file:", path)
        return
    }

    defer delete(data, context.allocator)

    str := string(data)
    str = strings.trim(str, " \n\r\t")

    for line in strings.split_lines_iterator(&str) {
        lists := strings.fields(line) or_break
        assert(len(lists) == 2)

        append(&ids_left , strconv.atoi(lists[0]))
        append(&ids_right, strconv.atoi(lists[1]))
    }
}

main :: proc() {
    read_and_parse(os.args[1])

    { // part 1
        slice.sort(ids_left[:])
        slice.sort(ids_right[:])

        sum := 0
        for v, i in soa_zip(l=ids_left[:], r=ids_right[:]) {
            dist := abs(v.l - v.r)
            sum += dist
        }

        fmt.println(sum)
    }

    { // part 2
        sum := 0
        for id_left in ids_left {
            appear := 0
            for id_right in ids_right {
                if id_right == id_left {
                    appear += 1
                }
            }
            sum += id_left * appear
        }

        fmt.println(sum)
    }
}
